import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

import 'network_demo_transport.dart';

/// Run with: flutter run -t lib/network_main.dart -d chrome
void main() {
  SPNetwork.init(
    config: SPNetworkConfig(baseUrl: 'https://demo.invalid/api/v2'),
    client: createNetworkDemoTransport(),
    closeClient: true,
  );
  runApp(const NetworkDemoApp());
}

/// Uses an offline mock transport, so no accounts or public server are needed.
class NetworkDemoApp extends StatelessWidget {
  const NetworkDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF5B5BD6)),
    home: const NetworkDemoPage(),
  );
}

class NetworkDemoPage extends StatefulWidget {
  const NetworkDemoPage({super.key});

  @override
  State<NetworkDemoPage> createState() => _NetworkDemoPageState();
}

class _NetworkDemoPageState extends State<NetworkDemoPage> {
  final SPNetwork _api = SPNetwork.instance;
  SPCancelToken? _cancellation;
  bool _busy = false;
  String _result = 'Choose an action. This demo makes no real network calls.';

  Future<void> _run(
    Future<SPNetworkResponse<Object?>> Function(SPRequestOptions) call,
  ) async {
    final cancellation = SPCancelToken();
    _cancellation = cancellation;
    setState(() {
      _busy = true;
      _result = 'Loading…';
    });
    try {
      final response = await call(SPRequestOptions(cancelToken: cancellation));
      if (!mounted) return;
      setState(() {
        _result =
            'HTTP ${response.statusCode} — ${response.attempts} attempt(s)\n'
            '${const JsonEncoder.withIndent('  ').convert(response.data)}';
      });
    } on SPNetworkException catch (error) {
      if (!mounted) return;
      setState(() {
        _result =
            '${error.type.name}: ${error.message}\n'
            'HTTP status: ${error.statusCode ?? 'none'}\n'
            '${error.body == null ? '' : jsonEncode(error.body)}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
      _cancellation = null;
    }
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    // This demo page is the app's only owner of its shared network client.
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const SPAppBar(title: 'Sixplace • SPNetwork'),
    body: SingleChildScrollView(
      child: SPContainer(
        padding: const EdgeInsets.all(16),
        child: SPRow(
          gap: 24,
          children: [
            SPCol(
              lg: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Offline networking demo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The application uses SPNetwork. A mock transport '
                    'simulates an API, including latency and failures.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (options) =>
                                _api.get<Object?>('items', options: options),
                          ),
                    child: const Text('GET: load items'),
                  ),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (options) => _api.post<Object?>(
                              'items',
                              body: {'title': 'New demo item'},
                              options: options,
                            ),
                          ),
                    child: const Text('POST: create item'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (options) =>
                                _api.get<Object?>('retry', options: options),
                          ),
                    child: const Text('GET: retry temporary 503'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (options) => _api.post<Object?>(
                              'validation',
                              body: {},
                              options: options,
                            ),
                          ),
                    child: const Text('POST: show validation error'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (options) => _api.upload<Object?>(
                              'files',
                              options: options,
                              fields: {'description': 'In-memory example'},
                              files: [
                                SPUploadFile(
                                  field: 'file',
                                  filename: 'demo.txt',
                                  bytes: utf8.encode('Sixplace upload demo'),
                                  contentType: 'text/plain',
                                ),
                              ],
                            ),
                          ),
                    child: const Text('Multipart: upload text file'),
                  ),
                  TextButton(
                    onPressed: _busy ? () => _cancellation?.cancel() : null,
                    child: const Text('Cancel current request'),
                  ),
                ],
              ),
            ),
            SPCol(
              lg: 7,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_busy) const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      SelectableText(_result),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
