@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/testing.dart';
import 'package:sixplace/network.dart';
import 'package:test/test.dart';

void main() {
  for (final error in <Object>[
    const SocketException('No route'),
    const HandshakeException('Certificate rejected'),
    const HttpException('Connection closed'),
  ]) {
    test(
      'classifies native ${error.runtimeType} without string matching',
      () async {
        final api = SPNetwork(
          config: SPNetworkConfig(
            baseUrl: 'https://example.com',
            retryPolicy: SPRetryPolicy.none,
          ),
          client: MockClient((_) async => throw error),
          closeClient: true,
        );
        addTearDown(api.close);
        await expectLater(
          api.get<Object?>('x'),
          throwsA(
            isA<SPNetworkException>().having(
              (e) => e.type,
              'type',
              SPNetworkErrorType.connection,
            ),
          ),
        );
      },
    );
  }

  test(
    'default IO transport reads JSON and sends multipart to loopback',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final receivedMethods = <String>[];
      final listener = server.listen((request) async {
        receivedMethods.add(request.method);
        if (request.method == 'POST') {
          final content = await utf8.decoder.bind(request).join();
          expect(content, contains('filename="demo.txt"'));
          expect(content, contains('Sixplace'));
          request.response.statusCode = 201;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"ok":true}');
        await request.response.close();
      });
      addTearDown(listener.cancel);
      final api = SPNetwork(
        config: SPNetworkConfig(
          baseUrl: 'http://127.0.0.1:${server.port}/api/v2',
          retryPolicy: SPRetryPolicy.none,
        ),
      );
      addTearDown(api.close);
      expect((await api.get<Map<String, dynamic>>('items')).data, {'ok': true});
      expect(
        (await api.upload<Object?>(
          'files',
          files: [
            SPUploadFile(
              field: 'file',
              filename: 'demo.txt',
              bytes: utf8.encode('Sixplace'),
            ),
          ],
        )).statusCode,
        201,
      );
      expect(receivedMethods, ['GET', 'POST']);
    },
  );
}
