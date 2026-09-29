// Compile-only check. Do not run: example.invalid is deliberately not a server.
// dart compile js tool/network_web_compile_check.dart -o /tmp/network_check.js
import 'package:sixplace/network.dart';

Future<void> main() async {
  final api = SPNetwork(
    config: SPNetworkConfig(
      baseUrl: 'https://example.invalid/api/',
      retryPolicy: SPRetryPolicy.none,
    ),
  );
  try {
    await api.get<Object?>('items');
    await api.post<Object?>('items', body: {'name': 'example'});
    await api.upload<Object?>(
      'files',
      files: [
        SPUploadFile(field: 'file', filename: 'example.txt', bytes: [65]),
      ],
    );
  } finally {
    api.close();
  }
}
