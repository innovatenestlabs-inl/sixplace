import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixplace/network.dart';
import 'package:test/test.dart';

TypeMatcher<SPNetworkException> failure(
  SPNetworkErrorType type, {
  int? status,
}) => isA<SPNetworkException>()
    .having((e) => e.type, 'type', type)
    .having((e) => e.statusCode, 'status', status);

void main() {
  SPNetwork make(
    http.Client transport, {
    SPTokenProvider? tokenProvider,
    SPUnauthorizedHandler? onUnauthorized,
    SPNetworkLogger? logger,
    SPRetryPolicy? retryPolicy,
    Duration timeout = const Duration(seconds: 1),
    int maxResponseBytes = 1024 * 1024,
    Map<String, String> headers = const {},
  }) {
    final network = SPNetwork(
      client: transport,
      config: SPNetworkConfig(
        baseUrl: 'https://example.com/api/v2',
        headers: headers,
        tokenProvider: tokenProvider,
        onUnauthorized: onUnauthorized,
        logger: logger,
        timeout: timeout,
        maxResponseBytes: maxResponseBytes,
        retryPolicy: retryPolicy ?? SPRetryPolicy(initialDelay: Duration.zero),
      ),
    );
    addTearDown(network.close);
    addTearDown(transport.close);
    return network;
  }

  group('configuration and lifecycle', () {
    test('validates base URLs in release mode', () {
      for (final value in [
        '',
        'localhost',
        'ftp://example.com',
        'https://user:password@example.com',
        'https://example.com?a=1',
        'https://example.com/#fragment',
      ]) {
        expect(() => SPNetworkConfig(baseUrl: value), throwsArgumentError);
      }
      expect(
        SPNetworkConfig(baseUrl: 'https://example.com/api/v2').baseUri,
        Uri.parse('https://example.com/api/v2/'),
      );
    });

    test('validates durations, buffer limits and retry configuration', () {
      expect(
        () => SPNetworkConfig(
          baseUrl: 'https://example.com',
          timeout: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => SPNetworkConfig(
          baseUrl: 'https://example.com',
          maxResponseBytes: 0,
        ),
        throwsArgumentError,
      );
      expect(() => SPRetryPolicy(maxAttempts: 0), throwsArgumentError);
      expect(() => SPRetryPolicy(maxAttempts: 11), throwsArgumentError);
      expect(() => SPRetryPolicy(multiplier: double.nan), throwsArgumentError);
      expect(
        () => SPRetryPolicy(multiplier: double.infinity),
        throwsArgumentError,
      );
      expect(() => SPRetryPolicy(maxDelay: Duration.zero), throwsArgumentError);
      expect(() => SPRetryPolicy(statusCodes: {401}), throwsArgumentError);
      expect(() => SPRetryPolicy(statusCodes: {403}), throwsArgumentError);
      expect(
        SPRetryPolicy(
          initialDelay: Duration.zero,
          multiplier: 1e308,
        ).delayAfter(10),
        Duration.zero,
      );
      expect(SPRetryPolicy().delayAfter(8), const Duration(seconds: 5));
    });

    test(
      'shared initialization is explicit and can be closed/reinitialized',
      () {
        expect(SPNetwork.isInitialized, isFalse);
        expect(() => SPNetwork.instance, throwsStateError);
        final transport = MockClient((_) async => http.Response('{}', 200));
        final config = SPNetworkConfig(baseUrl: 'https://example.com');
        final shared = SPNetwork.init(config: config, client: transport);
        addTearDown(shared.close);
        addTearDown(transport.close);
        expect(identical(shared, SPNetwork.instance), isTrue);
        expect(() => SPNetwork.init(config: config), throwsStateError);
        shared.close();
        shared.close();
        expect(SPNetwork.isInitialized, isFalse);
        expect(() => shared.get<Object?>('x'), throwsStateError);
        expect(() => shared.resetUnauthorizedState(), throwsStateError);
        SPNetwork.init(config: config, client: transport).close();
      },
    );

    test('caller owns injected transport unless ownership is transferred', () {
      final transport = TrackingClient((_) async => streamed('{}'));
      final first = make(transport);
      first.close();
      expect(transport.closeCount, 0);
      final owned = SPNetwork(
        config: first.config,
        client: transport,
        closeClient: true,
      );
      owned.close();
      owned.close();
      expect(transport.closeCount, 1);
    });
  });

  group('requests and responses', () {
    test(
      'preserves base path, leading slash, UTF-8 and query merging',
      () async {
        final api = make(
          MockClient((request) async {
            expect(request.url.path, '/api/v2/items');
            expect(request.url.queryParameters['existing'], 'yes');
            expect(request.url.queryParameters['page'], '2');
            expect(request.url.queryParameters['search'], 'বাংলা & value');
            expect(request.url.queryParametersAll['tag'], ['one', 'two']);
            expect(request.url.queryParameters.containsKey('missing'), isFalse);
            expect(request.headers.containsKey('content-type'), isFalse);
            return http.Response.bytes(utf8.encode('{"name":"বাংলা"}'), 200);
          }),
        );
        final result = await api.get<String>(
          '/items?existing=yes',
          queryParameters: {
            'page': 2,
            'search': 'বাংলা & value',
            'tag': ['one', 'two'],
            'missing': null,
          },
          decoder: (value) => (value as Map<String, dynamic>)['name'] as String,
        );
        expect(result.data, 'বাংলা');
        expect(result.attempts, 1);
        expect(() => result.headers['x'] = 'y', throwsUnsupportedError);
        expect(() => result.bodyBytes[0] = 0, throwsUnsupportedError);
      },
    );

    test(
      'rejects absolute URLs and base path traversal before sending',
      () async {
        var sends = 0;
        final api = make(
          MockClient((_) async {
            sends++;
            return http.Response('{}', 200);
          }),
        );
        for (final endpoint in [
          'https://evil.example/steal',
          '//evil.example/x',
          '../x',
          '%2e%2e/x',
          'x#fragment',
          r'..\x',
        ]) {
          await expectLater(api.get<Object?>(endpoint), throwsArgumentError);
        }
        expect(sends, 0);
      },
    );

    test(
      'all write verbs encode JSON once and merge headers case-insensitively',
      () async {
        final seen = <String>[];
        final api = make(
          MockClient((request) async {
            seen.add(request.method);
            expect(jsonDecode(request.body), {'message': 'বাংলা'});
            expect(request.headers['x-trace'], 'local');
            expect(
              request.headers['content-type'],
              contains('application/json'),
            );
            return http.Response('{"ok":true}', 201);
          }),
          headers: {'X-Trace': 'global'},
        );
        for (final method in [
          SPHttpMethod.post,
          SPHttpMethod.put,
          SPHttpMethod.patch,
          SPHttpMethod.delete,
        ]) {
          final result = await api.request<Map<String, dynamic>>(
            'items',
            method: method,
            body: {'message': 'বাংলা'},
            options: const SPRequestOptions(headers: {'x-trace': 'local'}),
          );
          expect(result.data, {'ok': true});
        }
        expect(seen, ['POST', 'PUT', 'PATCH', 'DELETE']);
      },
    );

    test('GET and HEAD refuse bodies; invalid timeout never sends', () async {
      final api = make(MockClient((_) async => http.Response('{}', 200)));
      expect(
        () => api.request<Object?>('x', method: SPHttpMethod.get, body: {}),
        throwsArgumentError,
      );
      await expectLater(
        api.get<Object?>(
          'x',
          options: const SPRequestOptions(timeout: Duration.zero),
        ),
        throwsArgumentError,
      );
    });

    for (final status in [200, 204, 205]) {
      test('empty $status succeeds without invoking decoder', () async {
        final api = make(MockClient((_) async => http.Response('', status)));
        final result = await api.get<String>(
          'x',
          decoder: (_) => throw StateError('called'),
        );
        expect(result.data, isNull);
        expect(result.statusCode, status);
      });
    }

    test('HEAD ignores body and JSON null is valid', () async {
      final api = make(
        MockClient(
          (request) async => http.Response(
            request.method == 'HEAD' ? 'not JSON' : 'null',
            200,
          ),
        ),
      );
      expect((await api.head('x')).data, isNull);
      expect((await api.get<Object?>('x')).data, isNull);
    });

    test('supports JSON arrays, text and bytes', () async {
      final api = make(MockClient((_) async => http.Response('[1,2]', 200)));
      expect((await api.get<List<dynamic>>('x')).data, [1, 2]);
      expect(
        (await api.get<String>(
          'x',
          options: const SPRequestOptions(responseType: SPResponseType.text),
        )).data,
        '[1,2]',
      );
      expect(
        (await api.get<List<int>>(
          'x',
          options: const SPRequestOptions(responseType: SPResponseType.bytes),
        )).data,
        utf8.encode('[1,2]'),
      );
    });

    test(
      'malformed success is a decoding failure, never a fake HTTP 500',
      () async {
        var calls = 0;
        final api = make(
          MockClient((_) async {
            calls++;
            return http.Response('<html>bad</html>', 200);
          }),
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.decoding, status: 200)),
        );
        expect(calls, 1);
      },
    );

    test('model decoder errors are classified and are not retried', () async {
      final api = make(MockClient((_) async => http.Response('{}', 200)));
      await expectLater(
        api.get<int>('x', decoder: (_) => throw StateError('model')),
        throwsA(failure(SPNetworkErrorType.decoding, status: 200)),
      );
    });

    test(
      'non-JSON server failure preserves its actual status and body',
      () async {
        final api = make(
          MockClient((_) async => http.Response('<h1>Failure</h1>', 500)),
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(
            failure(
              SPNetworkErrorType.http,
              status: 500,
            ).having((e) => e.body, 'body', '<h1>Failure</h1>'),
          ),
        );
      },
    );

    test('JSON backend validation details remain available', () async {
      final api = make(
        MockClient(
          (_) async => http.Response(
            '{"message":"Invalid","errors":{"email":["Required"]}}',
            422,
          ),
        ),
      );
      await expectLater(
        api.post<Object?>('x', body: {}),
        throwsA(
          failure(
            SPNetworkErrorType.http,
            status: 422,
          ).having((e) => (e.body as Map)['message'], 'message', 'Invalid'),
        ),
      );
    });

    test('redirects are not followed with backend credentials', () async {
      final transport = TrackingClient((request) async {
        expect(request.followRedirects, isFalse);
        return streamed(
          '',
          status: 302,
          headers: {'location': 'https://other.example'},
        );
      });
      final api = make(transport, tokenProvider: () => 'private');
      await expectLater(
        api.get<Object?>('x'),
        throwsA(failure(SPNetworkErrorType.http, status: 302)),
      );
    });

    test(
      'multipart files are fresh, with a generated content boundary',
      () async {
        final original = [65, 66, 67];
        final file = SPUploadFile(
          field: 'attachment',
          filename: 'report.txt',
          bytes: original,
          contentType: 'text/plain',
        );
        original[0] = 90;
        var sends = 0;
        final api = make(
          TrackingClient((request) async {
            final bytes = await request.finalize().toBytes();
            final body = utf8.decode(bytes);
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data; boundary='),
            );
            expect(body, contains('filename="report.txt"'));
            expect(body, contains('ABC'));
            expect(body, contains('memo'));
            sends++;
            return streamed('{}', status: 201);
          }),
          headers: {'Content-Type': 'application/json'},
        );
        await api.upload<Object?>(
          'files',
          files: [file],
          fields: {'type': 'memo'},
        );
        await api.upload<Object?>(
          'files',
          files: [file],
          fields: {'type': 'memo'},
        );
        expect(sends, 2);
      },
    );
  });

  group('retry boundaries', () {
    test('maxAttempts includes the first attempt', () async {
      var count = 0;
      final api = make(
        MockClient((_) async {
          count++;
          return http.Response('{}', count < 3 ? 503 : 200);
        }),
      );
      expect((await api.get<Object?>('x')).attempts, 3);
      expect(count, 3);
    });

    test('returns the last HTTP failure after exhaustion', () async {
      var count = 0;
      final api = make(
        MockClient((_) async {
          count++;
          return http.Response('{}', 503);
        }),
      );
      await expectLater(
        api.get<Object?>('x'),
        throwsA(
          failure(
            SPNetworkErrorType.http,
            status: 503,
          ).having((e) => e.attempt, 'attempt', 3),
        ),
      );
      expect(count, 3);
    });

    test(
      'retries transport failures, including body download errors',
      () async {
        var count = 0;
        final api = make(
          TrackingClient((_) async {
            count++;
            return count == 1
                ? http.StreamedResponse(
                    Stream<List<int>>.error(
                      http.ClientException('connection closed'),
                    ),
                    200,
                  )
                : streamed('{}');
          }),
        );
        expect((await api.get<Object?>('x')).attempts, 2);
      },
    );

    test('unknown/programmer transport errors are not retried', () async {
      var count = 0;
      final api = make(
        TrackingClient((_) async {
          count++;
          throw StateError('broken transport');
        }),
      );
      await expectLater(api.get<Object?>('x'), throwsStateError);
      expect(count, 1);
    });

    for (final method in [
      SPHttpMethod.post,
      SPHttpMethod.put,
      SPHttpMethod.patch,
      SPHttpMethod.delete,
    ]) {
      test('${method.name} does not replay after connection failure', () async {
        var count = 0;
        final api = make(
          MockClient((_) async {
            count++;
            throw http.ClientException('connection lost');
          }),
        );
        await expectLater(
          api.request<Object?>('x', method: method, body: {}),
          throwsA(failure(SPNetworkErrorType.connection)),
        );
        expect(count, 1);
      });
    }

    test('POST and multipart do not replay on HTTP 503 either', () async {
      var count = 0;
      final api = make(
        MockClient((_) async {
          count++;
          return http.Response('{}', 503);
        }),
      );
      await expectLater(
        api.post<Object?>('x'),
        throwsA(failure(SPNetworkErrorType.http, status: 503)),
      );
      await expectLater(
        api.upload<Object?>('x', files: []),
        throwsA(failure(SPNetworkErrorType.http, status: 503)),
      );
      expect(count, 2);
    });

    test(
      'Retry-After zero retries; values beyond cap return immediately',
      () async {
        var count = 0;
        final api = make(
          MockClient((_) async {
            count++;
            return http.Response(
              '{}',
              429,
              headers: {'retry-after': count == 1 ? '0' : '3600'},
            );
          }),
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.http, status: 429)),
        );
        expect(count, 2);
      },
    );

    test('Retry-After HTTP dates in the past allow a retry', () async {
      var count = 0;
      final api = make(
        MockClient((_) async {
          count++;
          return http.Response(
            '{}',
            count == 1 ? 503 : 200,
            headers: {'retry-after': 'Wed, 21 Oct 2015 07:28:00 GMT'},
          );
        }),
      );
      expect((await api.get<Object?>('x')).attempts, 2);
    });

    test('per-request retry policy can disable retries', () async {
      var count = 0;
      final api = make(
        MockClient((_) async {
          count++;
          throw http.ClientException('unreachable');
        }),
      );
      await expectLater(
        api.get<Object?>(
          'x',
          options: SPRequestOptions(retryPolicy: SPRetryPolicy.none),
        ),
        throwsA(failure(SPNetworkErrorType.connection)),
      );
      expect(count, 1);
    });
  });

  group('authentication and privacy', () {
    test('provider is read afresh and request tokens override it', () async {
      var token = 'first';
      final auth = <String?>[];
      final api = make(
        MockClient((request) async {
          auth.add(request.headers['authorization']);
          return http.Response('{}', 200);
        }),
        tokenProvider: () async => token,
      );
      await api.get<Object?>('x');
      token = 'second';
      await api.get<Object?>('x');
      await api.get<Object?>(
        'x',
        options: const SPRequestOptions(token: 'manual'),
      );
      await api.get<Object?>('x', options: const SPRequestOptions(token: ''));
      expect(auth, ['Bearer first', 'Bearer second', 'Bearer manual', null]);
    });

    test(
      'public login removes Authorization and never invokes session cleanup',
      () async {
        var providers = 0;
        var unauthorized = 0;
        final api = make(
          MockClient((request) async {
            expect(request.headers.containsKey('authorization'), isFalse);
            return http.Response('{"message":"Invalid credentials"}', 401);
          }),
          headers: {'Authorization': 'Bearer stale'},
          tokenProvider: () {
            providers++;
            return 'new';
          },
          onUnauthorized: (_) {
            unauthorized++;
          },
        );
        await expectLater(
          api.post<Object?>(
            'login',
            options: const SPRequestOptions(authenticated: false),
          ),
          throwsA(failure(SPNetworkErrorType.http, status: 401)),
        );
        expect(providers, 0);
        expect(unauthorized, 0);
      },
    );

    test(
      '401 without sent credentials and 403 never trigger cleanup',
      () async {
        var unauthorized = 0;
        final api = make(
          MockClient(
            (request) async => http.Response(
              '',
              request.url.path.endsWith('forbidden') ? 403 : 401,
            ),
          ),
          onUnauthorized: (_) {
            unauthorized++;
          },
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.http, status: 401)),
        );
        await expectLater(
          api.get<Object?>(
            'forbidden',
            options: const SPRequestOptions(token: 'token'),
          ),
          throwsA(failure(SPNetworkErrorType.http, status: 403)),
        );
        expect(unauthorized, 0);
      },
    );

    test(
      'concurrent 401s invoke handler once, reset allows a new session',
      () async {
        var unauthorized = 0;
        final api = make(
          MockClient((_) async => http.Response('expired', 401)),
          tokenProvider: () => 'private',
          onUnauthorized: (_) async {
            unauthorized++;
            await Future<void>.delayed(const Duration(milliseconds: 5));
          },
        );
        await Future.wait(
          List.generate(
            5,
            (_) => expectLater(
              api.get<Object?>('x'),
              throwsA(failure(SPNetworkErrorType.http, status: 401)),
            ),
          ),
        );
        expect(unauthorized, 1);
        api.resetUnauthorizedState();
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.http, status: 401)),
        );
        expect(unauthorized, 2);
      },
    );

    test(
      'late old-session 401 does not log out a newly signed-in user',
      () async {
        final started = Completer<void>();
        final result = Completer<http.Response>();
        var unauthorized = 0;
        final api = make(
          MockClient((_) {
            started.complete();
            return result.future;
          }),
          tokenProvider: () => 'old',
          onUnauthorized: (_) {
            unauthorized++;
          },
        );
        final pending = api.get<Object?>('x');
        final assertion = expectLater(
          pending,
          throwsA(failure(SPNetworkErrorType.http, status: 401)),
        );
        await started.future;
        api.resetUnauthorizedState();
        result.complete(http.Response('', 401));
        await assertion;
        expect(unauthorized, 0);
      },
    );

    test(
      'provider failures are typed, callback failures preserve 401',
      () async {
        final api = make(
          MockClient((_) async => http.Response('', 401)),
          tokenProvider: () => throw StateError('secret'),
          onUnauthorized: (_) => throw StateError('callback'),
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.authentication)),
        );
        await expectLater(
          api.get<Object?>(
            'x',
            options: const SPRequestOptions(token: 'value'),
          ),
          throwsA(failure(SPNetworkErrorType.http, status: 401)),
        );
      },
    );

    test(
      'logs and exception toString never expose private request data',
      () async {
        final events = <String>[];
        final api = make(
          MockClient(
            (_) async => http.Response('{"message":"secret-response"}', 400),
          ),
          tokenProvider: () => 'secret-token',
          logger: (event) {
            events.add(event.toString());
          },
        );
        try {
          await api.post<Object?>(
            'secret-path?key=secret-query',
            body: {'password': 'secret-password'},
          );
          fail('Expected HTTP failure');
        } on SPNetworkException catch (error) {
          events.add(error.toString());
        }
        expect(events.join(), isNot(contains('secret-')));
      },
    );

    test('logger errors cannot change a successful result', () async {
      final api = make(
        MockClient((_) async => http.Response('{}', 200)),
        logger: (_) => throw StateError('logging'),
      );
      expect((await api.get<Object?>('x')).statusCode, 200);
    });
  });

  group('timeouts, cancellation and buffering', () {
    test('timeout before headers signals transport abort', () async {
      final aborted = Completer<void>();
      final api = make(
        TrackingClient((request) {
          (request as http.Abortable).abortTrigger!.then(
            (_) => aborted.complete(),
          );
          return Completer<http.StreamedResponse>().future;
        }),
        timeout: const Duration(milliseconds: 30),
        retryPolicy: SPRetryPolicy.none,
      );
      await expectLater(
        api.get<Object?>('x'),
        throwsA(failure(SPNetworkErrorType.timeout)),
      );
      await aborted.future;
    });

    test(
      'timeout includes a stalled body and cancels its subscription',
      () async {
        var cancelled = false;
        final body = StreamController<List<int>>(
          onCancel: () {
            cancelled = true;
          },
        );
        addTearDown(body.close);
        final api = make(
          TrackingClient((_) async => http.StreamedResponse(body.stream, 200)),
          timeout: const Duration(milliseconds: 30),
          retryPolicy: SPRetryPolicy.none,
        );
        await expectLater(
          api.get<Object?>('x'),
          throwsA(failure(SPNetworkErrorType.timeout)),
        );
        expect(cancelled, isTrue);
      },
    );

    test('pre-cancelled request never sends', () async {
      var sends = 0;
      final api = make(
        MockClient((_) async {
          sends++;
          return http.Response('{}', 200);
        }),
      );
      final token = SPCancelToken()..cancel();
      await expectLater(
        api.get<Object?>('x', options: SPRequestOptions(cancelToken: token)),
        throwsA(failure(SPNetworkErrorType.cancelled)),
      );
      expect(sends, 0);
    });

    test('cancellation interrupts backoff and prevents another send', () async {
      final token = SPCancelToken();
      var sends = 0;
      final api = make(
        MockClient((_) async {
          sends++;
          return http.Response('{}', 503);
        }),
        retryPolicy: SPRetryPolicy(initialDelay: const Duration(seconds: 2)),
        logger: (event) {
          if (event.phase == 'retry') token.cancel();
        },
      );
      await expectLater(
        api.get<Object?>('x', options: SPRequestOptions(cancelToken: token)),
        throwsA(failure(SPNetworkErrorType.cancelled)),
      );
      expect(sends, 1);
    });

    test('closing the client cancels an in-flight body', () async {
      final ready = Completer<void>();
      final body = StreamController<List<int>>();
      addTearDown(body.close);
      final api = make(
        TrackingClient((_) async {
          ready.complete();
          return http.StreamedResponse(body.stream, 200);
        }),
      );
      final pending = api.get<Object?>('x');
      final assertion = expectLater(
        pending,
        throwsA(failure(SPNetworkErrorType.cancelled)),
      );
      await ready.future;
      api.close();
      await assertion;
    });

    test('buffer limit is enforced without retrying', () async {
      var sends = 0;
      final api = make(
        TrackingClient((_) async {
          sends++;
          return streamed('123456');
        }),
        maxResponseBytes: 5,
      );
      await expectLater(
        api.get<Object?>('x'),
        throwsA(failure(SPNetworkErrorType.responseTooLarge)),
      );
      expect(sends, 1);
    });
  });

  group('device/backend reachability', () {
    test(
      'isDeviceOnline performs exactly one unauthenticated HEAD request',
      () async {
        var sends = 0;
        String? method;
        String? authorization;

        final api = make(
          MockClient((request) async {
            sends++;
            method = request.method;
            authorization = request.headers['authorization'];

            return http.Response('', 204);
          }),
          tokenProvider: () async => 'secret-token',
        );

        final result = await api.isDeviceOnline(endpoint: 'health');

        expect(result, isTrue);
        expect(sends, 1);
        expect(method, 'HEAD');
        expect(authorization, isNull);
      },
    );

    test(
      'isDeviceOnline treats an HTTP response as reachable without retrying',
      () async {
        var sends = 0;

        final api = make(
          MockClient((_) async {
            sends++;
            return http.Response('', 503);
          }),
        );

        final result = await api.isDeviceOnline(endpoint: 'health');

        expect(result, isTrue);
        expect(sends, 1);
      },
    );

    test(
      'isDeviceOnline returns false on connection failure without retrying',
      () async {
        var sends = 0;

        final api = make(
          MockClient((_) async {
            sends++;
            throw http.ClientException('Server unavailable');
          }),
        );

        final result = await api.isDeviceOnline(endpoint: 'health');

        expect(result, isFalse);
        expect(sends, 1);
      },
    );
  });
}

http.StreamedResponse streamed(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
);

class TrackingClient extends http.BaseClient {
  TrackingClient(this.handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  int closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);

  @override
  void close() {
    closeCount++;
  }
}
