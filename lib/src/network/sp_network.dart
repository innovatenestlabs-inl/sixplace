import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'internal/transport_error_stub.dart'
    if (dart.library.io) 'internal/transport_error_io.dart';
import 'sp_cancel_token.dart';
import 'sp_network_config.dart';
import 'sp_network_exception.dart';
import 'sp_network_response.dart';
import 'sp_request_options.dart';
import 'sp_retry_policy.dart';
import 'sp_upload_file.dart';

/// Supported HTTP verbs. Only GET and HEAD are automatically retried.
enum SPHttpMethod {
  /// Reads a resource.
  get,

  /// Creates or submits data.
  post,

  /// Replaces a resource; not automatically retried.
  put,

  /// Partially updates a resource.
  patch,

  /// Deletes a resource; not automatically retried.
  delete,

  /// Reads response headers without decoding a body.
  head,
}

/// Persistent, UI-independent client with an optional shared instance.
///
/// Create one instance per backend and reuse it. Call [close] when its owner is
/// disposed, not after every request. An injected [http.Client] stays owned by
/// its caller unless `closeClient` is true.
class SPNetwork {
  /// Creates an independent client. This does not initialize [instance].
  SPNetwork({
    required this.config,
    http.Client? client,
    bool closeClient = false,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null || closeClient;

  static SPNetwork? _shared;

  /// Initializes the shared client once, normally before runApp.
  ///
  /// Calling twice throws instead of silently replacing a live client.
  /// Close the old instance before initializing a replacement.
  static SPNetwork init({
    required SPNetworkConfig config,
    http.Client? client,
    bool closeClient = false,
  }) {
    if (_shared != null) {
      throw StateError('SPNetwork is already initialized. Close it first.');
    }
    return _shared = SPNetwork(
      config: config,
      client: client,
      closeClient: closeClient,
    );
  }

  /// Whether a live shared instance exists.
  static bool get isInitialized => _shared != null;

  /// The shared client. Throws until [init] has been called.
  static SPNetwork get instance =>
      _shared ??
      (throw StateError('Call SPNetwork.init before SPNetwork.instance.'));

  /// Configuration for this backend.
  final SPNetworkConfig config;
  final http.Client _client;
  final bool _ownsClient;
  final Set<SPCancelToken> _active = {};
  bool _closed = false;
  bool _unauthorizedHandled = false;
  int _authGeneration = 0;

  /// Whether this client has been permanently closed.
  bool get isClosed => _closed;

  /// Re-arms the unauthorized callback after a successful new login.
  ///
  /// Late 401 responses from calls started in the old session are ignored by
  /// the callback. The requests themselves still complete with HTTP errors.
  void resetUnauthorizedState() {
    _ensureOpen();
    _authGeneration++;
    _unauthorizedHandled = false;
  }

  /// Sends a GET. [decoder] maps the decoded body, not an assumed data envelope.
  Future<SPNetworkResponse<T>> get<T>(
    String endpoint, {
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) => request<T>(
    endpoint,
    method: SPHttpMethod.get,
    queryParameters: queryParameters,
    options: options,
    decoder: decoder,
  );

  /// Sends a POST. [body] is JSON-encoded once; do not pre-encode it.
  Future<SPNetworkResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) => request<T>(
    endpoint,
    method: SPHttpMethod.post,
    body: body,
    queryParameters: queryParameters,
    options: options,
    decoder: decoder,
  );

  /// Sends a PUT exactly once, without automatic replay.
  Future<SPNetworkResponse<T>> put<T>(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) => request<T>(
    endpoint,
    method: SPHttpMethod.put,
    body: body,
    queryParameters: queryParameters,
    options: options,
    decoder: decoder,
  );

  /// Sends a PATCH exactly once, without automatic replay.
  Future<SPNetworkResponse<T>> patch<T>(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) => request<T>(
    endpoint,
    method: SPHttpMethod.patch,
    body: body,
    queryParameters: queryParameters,
    options: options,
    decoder: decoder,
  );

  /// Sends a DELETE exactly once. Supports an optional JSON body.
  Future<SPNetworkResponse<T>> delete<T>(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) => request<T>(
    endpoint,
    method: SPHttpMethod.delete,
    body: body,
    queryParameters: queryParameters,
    options: options,
    decoder: decoder,
  );

  /// Sends a HEAD. Its response data is always null.
  Future<SPNetworkResponse<Object?>> head(
    String endpoint, {
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
  }) => request<Object?>(
    endpoint,
    method: SPHttpMethod.head,
    queryParameters: queryParameters,
    options: options,
  );

  // ============================================================
  // DEVICE / BACKEND REACHABILITY CHECK
  // ============================================================

  /// Checks whether the configured backend is currently reachable.
  ///
  /// This performs a lightweight unauthenticated HEAD request against
  /// [endpoint]. No retries are performed.
  ///
  /// A received HTTP response means that the network path to the backend exists,
  /// even if the backend returns a non-success status such as 401, 404 or 500.
  ///
  /// Connection failures, DNS/TLS failures and timeouts return false.
  ///
  /// This is a point-in-time reachability check. Network state may change
  /// immediately after this method completes.
  Future<bool> isDeviceOnline({
    String endpoint = '',
    Duration timeout = const Duration(seconds: 3),
  }) async {
    _ensureOpen();

    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }

    try {
      await head(
        endpoint,
        options: SPRequestOptions(
          authenticated: false,
          timeout: timeout,
          retryPolicy: SPRetryPolicy.none,
        ),
      );

      return true;
    } on SPNetworkException catch (error) {
      if (error.type == SPNetworkErrorType.http) {
        // Server responded, so network/backend is reachable.
        return true;
      }

      if (error.type == SPNetworkErrorType.connection ||
          error.type == SPNetworkErrorType.timeout) {
        return false;
      }

      rethrow;
    }
  }

  /// Sends a JSON request using any supported verb.
  ///
  /// Endpoints are relative to the base directory. One leading slash is
  /// tolerated without removing the configured base path. Absolute URLs,
  /// network-path references and paths escaping the base are rejected.
  /// Query values may be scalars or iterables; null values are omitted.
  Future<SPNetworkResponse<T>> request<T>(
    String endpoint, {
    required SPHttpMethod method,
    Object? body,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) {
    _ensureOpen();
    if ((method == SPHttpMethod.get || method == SPHttpMethod.head) &&
        body != null) {
      throw ArgumentError('GET and HEAD do not accept a body.');
    }
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    return _execute<T>(endpoint, method, queryParameters, options, decoder, (
      uri,
      headers,
      abort,
    ) {
      final request = http.AbortableRequest(
        method.name.toUpperCase(),
        uri,
        abortTrigger: abort,
      );
      request.headers.addAll(headers);
      if (bytes != null) {
        request.headers.putIfAbsent(
          'content-type',
          () => 'application/json; charset=utf-8',
        );
        request.bodyBytes = bytes;
      }
      return request;
    });
  }

  /// Sends a multipart POST, PUT or PATCH exactly once.
  ///
  /// Sixplace creates fresh multipart parts; it never reuses consumed streams.
  /// Content-Type is generated with the correct multipart boundary.
  Future<SPNetworkResponse<T>> upload<T>(
    String endpoint, {
    required List<SPUploadFile> files,
    Map<String, String> fields = const {},
    SPHttpMethod method = SPHttpMethod.post,
    Map<String, Object?>? queryParameters,
    SPRequestOptions options = const SPRequestOptions(),
    T Function(Object? body)? decoder,
  }) {
    _ensureOpen();
    if (!{
      SPHttpMethod.post,
      SPHttpMethod.put,
      SPHttpMethod.patch,
    }.contains(method)) {
      throw ArgumentError('Uploads support POST, PUT and PATCH only.');
    }
    final savedFiles = List<SPUploadFile>.of(files);
    final savedFields = Map<String, String>.of(fields);
    return _execute<T>(endpoint, method, queryParameters, options, decoder, (
      uri,
      headers,
      abort,
    ) {
      final request = http.AbortableMultipartRequest(
        method.name.toUpperCase(),
        uri,
        abortTrigger: abort,
      );
      request.headers.addAll({...headers}..remove('content-type'));
      request.fields.addAll(savedFields);
      request.files.addAll(savedFiles.map((file) => file.toMultipartFile()));
      return request;
    });
  }

  Future<SPNetworkResponse<T>> _execute<T>(
    String endpoint,
    SPHttpMethod method,
    Map<String, Object?>? query,
    SPRequestOptions options,
    T Function(Object?)? decoder,
    http.BaseRequest Function(Uri, Map<String, String>, Future<void>) build,
  ) async {
    _ensureOpen();
    final uri = _resolveUri(endpoint, query);
    final verb = method.name.toUpperCase();
    final timeout = options.timeout ?? config.timeout;
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    final headers = <String, String>{
      'accept': 'application/json',
      for (final entry in config.headers.entries)
        entry.key.toLowerCase(): entry.value,
      for (final entry in options.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };
    // Computed by the transport, never trust stale body lengths.
    headers.remove('content-length');
    final generation = _authGeneration;
    final cancellation = SPCancelToken();
    final unsubscribe = options.cancelToken?.addListener(cancellation.cancel);
    _active.add(cancellation);
    SPNetworkException cancelled() => SPNetworkException(
      type: SPNetworkErrorType.cancelled,
      message: 'The request was cancelled.',
      method: verb,
      uri: uri,
    );
    try {
      if (cancellation.isCancelled) throw cancelled();
      if (!options.authenticated) {
        headers.remove('authorization');
      } else {
        String? token = options.token;
        if (token == null &&
            !headers.containsKey('authorization') &&
            config.tokenProvider != null) {
          try {
            token = await _cancellable(
              Future<String?>.sync(config.tokenProvider!).timeout(timeout),
              cancellation,
              cancelled,
            );
          } on SPNetworkException {
            rethrow;
          } catch (error, stack) {
            throw SPNetworkException(
              type: SPNetworkErrorType.authentication,
              message: 'Unable to obtain authentication credentials.',
              method: verb,
              uri: uri,
              cause: error,
              stackTrace: stack,
            );
          }
        }
        if (token != null) {
          headers.remove('authorization');
          if (token.trim().isNotEmpty) {
            if (token.contains('\r') || token.contains('\n')) {
              throw ArgumentError('Bearer tokens cannot contain line breaks.');
            }
            headers['authorization'] = 'Bearer ${token.trim()}';
          }
        }
      }
      final authenticated =
          options.authenticated &&
          (headers['authorization']?.trim().isNotEmpty ?? false);
      final policy = options.retryPolicy ?? config.retryPolicy;
      final attempts = method == SPHttpMethod.get || method == SPHttpMethod.head
          ? policy.maxAttempts
          : 1;
      for (var attempt = 1; attempt <= attempts; attempt++) {
        if (cancellation.isCancelled) throw cancelled();
        _log(SPNetworkLog(phase: 'request', method: verb, attempt: attempt));
        http.Response response;
        try {
          response = await _sendAttempt(
            uri,
            verb,
            headers,
            build,
            timeout,
            cancellation,
            attempt,
          );
        } on SPNetworkException catch (error) {
          final retryable =
              error.type == SPNetworkErrorType.connection ||
              error.type == SPNetworkErrorType.timeout;
          if (!retryable || attempt == attempts) rethrow;
          _log(
            SPNetworkLog(
              phase: 'retry',
              method: verb,
              attempt: attempt,
              errorType: error.type,
            ),
          );
          await _wait(policy.delayAfter(attempt), cancellation, cancelled);
          continue;
        }
        _log(
          SPNetworkLog(
            phase: 'response',
            method: verb,
            attempt: attempt,
            statusCode: response.statusCode,
          ),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final error = SPNetworkException(
            type: SPNetworkErrorType.http,
            message: 'The server returned HTTP ${response.statusCode}.',
            method: verb,
            uri: uri,
            statusCode: response.statusCode,
            headers: Map.unmodifiable(response.headers),
            body: _errorBody(response),
            attempt: attempt,
          );
          if (response.statusCode == 401 && authenticated) {
            await _notifyUnauthorized(
              error,
              generation,
              cancellation,
              cancelled,
            );
          }
          final delay = _retryDelay(response, policy, attempt);
          if (attempt < attempts &&
              delay != null &&
              policy.statusCodes.contains(response.statusCode)) {
            _log(
              SPNetworkLog(
                phase: 'retry',
                method: verb,
                attempt: attempt,
                statusCode: response.statusCode,
              ),
            );
            await _wait(delay, cancellation, cancelled);
            continue;
          }
          throw error;
        }
        if (cancellation.isCancelled) throw cancelled();
        T? data;
        try {
          final empty =
              response.bodyBytes.isEmpty ||
              method == SPHttpMethod.head ||
              response.statusCode == 204 ||
              response.statusCode == 205;
          if (!empty) {
            final Object? decoded = switch (options.responseType) {
              SPResponseType.json => jsonDecode(
                utf8.decode(response.bodyBytes),
              ),
              SPResponseType.text => _text(response),
              SPResponseType.bytes => Uint8List.fromList(
                response.bodyBytes,
              ).asUnmodifiableView(),
            };
            data = decoder != null ? decoder(decoded) : decoded as T?;
          }
        } catch (error, stack) {
          throw SPNetworkException(
            type: SPNetworkErrorType.decoding,
            message: 'The response could not be decoded.',
            method: verb,
            uri: uri,
            statusCode: response.statusCode,
            cause: error,
            stackTrace: stack,
            attempt: attempt,
          );
        }
        return SPNetworkResponse<T>(
          data: data,
          statusCode: response.statusCode,
          uri: uri,
          headers: response.headers,
          bodyBytes: response.bodyBytes,
          attempts: attempt,
        );
      }
      throw StateError('Unreachable request state.');
    } on SPNetworkException catch (error) {
      _log(
        SPNetworkLog(
          phase: 'error',
          method: verb,
          attempt: error.attempt,
          statusCode: error.statusCode,
          errorType: error.type,
        ),
      );
      rethrow;
    } finally {
      unsubscribe?.call();
      _active.remove(cancellation);
    }
  }

  Future<http.Response> _sendAttempt(
    Uri uri,
    String method,
    Map<String, String> headers,
    http.BaseRequest Function(Uri, Map<String, String>, Future<void>) build,
    Duration timeout,
    SPCancelToken cancellation,
    int attempt,
  ) async {
    final abort = Completer<void>();
    final completed = Completer<http.Response>();
    StreamSubscription<List<int>>? subscription;
    SPNetworkException failure(
      SPNetworkErrorType type,
      String message, [
      Object? cause,
      StackTrace? stack,
    ]) => SPNetworkException(
      type: type,
      message: message,
      method: method,
      uri: uri,
      cause: cause,
      stackTrace: stack,
      attempt: attempt,
    );
    void stop(Object error, [StackTrace? stack]) {
      if (completed.isCompleted) return;
      completed.completeError(error, stack);
      if (!abort.isCompleted) abort.complete();
      final current = subscription;
      if (current != null) {
        unawaited(current.cancel().catchError((Object _) {}));
      }
    }

    void transportError(Object error, StackTrace stack) {
      if (error is http.RequestAbortedException) {
        stop(
          failure(
            SPNetworkErrorType.cancelled,
            'The request was cancelled.',
            error,
            stack,
          ),
          stack,
        );
      } else if (error is TimeoutException) {
        stop(
          failure(
            SPNetworkErrorType.timeout,
            'The request timed out.',
            error,
            stack,
          ),
          stack,
        );
      } else if (error is http.ClientException ||
          isPlatformTransportError(error)) {
        stop(
          failure(
            SPNetworkErrorType.connection,
            'Unable to reach the server. Check your connection and try again.',
            error,
            stack,
          ),
          stack,
        );
      } else {
        // Programmer errors from custom transports must not be silently retried.
        stop(error, stack);
      }
    }

    final timer = Timer(
      timeout,
      () => stop(failure(SPNetworkErrorType.timeout, 'The request timed out.')),
    );
    final unsubscribe = cancellation.addListener(
      () => stop(
        failure(SPNetworkErrorType.cancelled, 'The request was cancelled.'),
      ),
    );
    try {
      if (!completed.isCompleted) {
        final request = build(uri, headers, abort.future)
          ..followRedirects = false;
        // Fail closed on redirects: do not forward backend credentials to a
        // Location URL. BrowserClient reports rejected redirects as failures.
        unawaited(
          Future<void>(() async {
            try {
              if (completed.isCompleted) return;
              final streamed = await _client.send(request);
              if (completed.isCompleted) {
                await streamed.stream.listen(null).cancel();
                return;
              }
              final bytes = BytesBuilder(copy: false);
              subscription = streamed.stream.listen(
                (chunk) {
                  if (completed.isCompleted) return;
                  if (bytes.length + chunk.length > config.maxResponseBytes) {
                    stop(
                      failure(
                        SPNetworkErrorType.responseTooLarge,
                        'The response exceeded the configured size limit.',
                      ),
                    );
                    return;
                  }
                  bytes.add(chunk);
                },
                onError: transportError,
                onDone: () {
                  if (completed.isCompleted) return;
                  completed.complete(
                    http.Response.bytes(
                      bytes.takeBytes(),
                      streamed.statusCode,
                      headers: streamed.headers,
                      reasonPhrase: streamed.reasonPhrase,
                      request: request,
                    ),
                  );
                },
                cancelOnError: true,
              );
            } catch (error, stack) {
              transportError(error, stack);
            }
          }),
        );
      }
      return await completed.future;
    } finally {
      timer.cancel();
      unsubscribe();
    }
  }

  Uri _resolveUri(String endpoint, Map<String, Object?>? query) {
    if (endpoint.contains('\\') || endpoint.startsWith('//')) {
      throw ArgumentError('Use a relative endpoint within the base URL.');
    }
    final relative = Uri.parse(
      endpoint.startsWith('/') ? endpoint.substring(1) : endpoint,
    );
    if (relative.hasScheme || relative.hasAuthority || relative.hasFragment) {
      throw ArgumentError(
        'Endpoints cannot contain a scheme, host or fragment.',
      );
    }
    for (final segment in relative.pathSegments) {
      if (segment == '..' ||
          segment == '.' ||
          segment.contains('/') ||
          segment.contains('\\')) {
        throw ArgumentError(
          'Endpoints cannot contain traversal or encoded slashes.',
        );
      }
    }
    var uri = config.baseUri.resolveUri(relative);
    if (uri.origin != config.baseUri.origin ||
        !uri.path.startsWith(config.baseUri.path)) {
      throw ArgumentError('Endpoint must stay within the configured base URL.');
    }
    if (query != null && query.isNotEmpty) {
      final merged = <String, dynamic>{...uri.queryParametersAll};
      for (final entry in query.entries) {
        final value = entry.value;
        if (value == null) continue;
        merged[entry.key] = value is Iterable
            ? value
                  .where((item) => item != null)
                  .map((item) => '$item')
                  .toList()
            : '$value';
      }
      uri = uri.replace(queryParameters: merged);
    }
    return uri;
  }

  static String _text(http.Response response) {
    final contentType = response.headers['content-type'];
    String? charset;
    if (contentType != null) {
      charset = MediaType.parse(contentType).parameters['charset'];
    }
    final encoding = charset == null ? utf8 : Encoding.getByName(charset);
    if (encoding == null) {
      throw FormatException('Unsupported response charset.');
    }
    return encoding.decode(response.bodyBytes);
  }

  static Object? _errorBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    // Never allow HTML, malformed JSON or a broken charset to hide HTTP status.
    String body;
    try {
      body = _text(response);
    } catch (_) {
      body = utf8.decode(response.bodyBytes, allowMalformed: true);
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static Duration? _retryDelay(
    http.Response response,
    SPRetryPolicy policy,
    int attempt,
  ) {
    final header = response.headers['retry-after'];
    if (header == null) return policy.delayAfter(attempt);
    Duration wait;
    final seconds = int.tryParse(header.trim());
    if (seconds != null) {
      if (seconds < 0) return policy.delayAfter(attempt);
      // Check before Duration multiplication to avoid huge integer values.
      if (seconds > policy.maxDelay.inSeconds) return null;
      wait = Duration(seconds: seconds);
    } else {
      try {
        wait = parseHttpDate(header).difference(DateTime.now().toUtc());
      } on FormatException {
        return policy.delayAfter(attempt);
      }
    }
    if (wait.isNegative) wait = Duration.zero;
    return wait > policy.maxDelay ? null : wait;
  }

  Future<void> _notifyUnauthorized(
    SPNetworkException error,
    int generation,
    SPCancelToken cancellation,
    SPNetworkException Function() cancelled,
  ) async {
    if (_unauthorizedHandled ||
        generation != _authGeneration ||
        config.onUnauthorized == null ||
        cancellation.isCancelled) {
      return;
    }
    _unauthorizedHandled = true;
    // Set the latch before invoking app code, preventing recursive 401 loops.
    try {
      await _cancellable(
        Future<void>.sync(
          () => config.onUnauthorized!(error),
        ).timeout(config.timeout),
        cancellation,
        cancelled,
      );
    } catch (_) {
      _log(
        SPNetworkLog(
          phase: 'unauthorizedCallbackError',
          method: error.method,
          attempt: error.attempt,
          statusCode: 401,
        ),
      );
      // Callback failures must not replace the original HTTP 401.
    }
  }

  static Future<T> _cancellable<T>(
    Future<T> future,
    SPCancelToken token,
    SPNetworkException Function() cancelled,
  ) async {
    final done = Completer<T>();
    final unsubscribe = token.addListener(() {
      if (!done.isCompleted) done.completeError(cancelled());
    });
    future.then(
      (value) {
        if (!done.isCompleted) done.complete(value);
      },
      onError: (Object error, StackTrace stack) {
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    try {
      return await done.future;
    } finally {
      unsubscribe();
    }
  }

  static Future<void> _wait(
    Duration delay,
    SPCancelToken token,
    SPNetworkException Function() cancelled,
  ) async {
    final done = Completer<void>();
    final timer = Timer(delay, done.complete);
    try {
      await _cancellable(done.future, token, cancelled);
    } finally {
      timer.cancel();
      if (!done.isCompleted) done.complete();
    }
  }

  void _log(SPNetworkLog event) {
    try {
      config.logger?.call(event);
    } catch (_) {
      // Diagnostic code cannot change HTTP outcomes.
    }
  }

  void _ensureOpen() {
    if (_closed) throw StateError('This SPNetwork client has been closed.');
  }

  /// Cancels active calls and releases owned connections. Safe to call twice.
  ///
  /// Injected transports are not closed unless ownership was explicitly passed.
  /// Custom transports must support Abortable requests for socket-level abort.
  void close() {
    if (_closed) return;
    _closed = true;
    for (final token in List<SPCancelToken>.of(_active)) {
      token.cancel();
    }
    if (_ownsClient) _client.close();
    if (identical(_shared, this)) _shared = null;
  }
}
