import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Offline demo transport only. Production apps let SPNetwork create its own
/// transport or inject a real HTTP client, not this fixture.
http.Client createNetworkDemoTransport() {
  var nextId = 3;
  var retryRequests = 0;
  final items = <Map<String, Object>>[
    {'id': 1, 'title': 'Responsive layout'},
    {'id': 2, 'title': 'SPNetwork foundation'},
  ];
  return MockClient((request) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final endpoint = request.url.pathSegments.last;
    if (endpoint == 'items' && request.method == 'GET') {
      return http.Response(jsonEncode({'items': items}), 200);
    }
    if (endpoint == 'items' && request.method == 'POST') {
      final input = jsonDecode(request.body) as Map<String, dynamic>;
      final item = <String, Object>{
        'id': nextId++,
        'title': input['title'] as String,
      };
      items.add(item);
      return http.Response(jsonEncode(item), 201);
    }
    if (endpoint == 'retry') {
      retryRequests++;
      return http.Response(
        jsonEncode({'message': 'Recovered after temporary failure'}),
        retryRequests % 3 == 0 ? 200 : 503,
      );
    }
    if (endpoint == 'validation') {
      return http.Response(
        jsonEncode({
          'message': 'Please enter a title.',
          'errors': {
            'title': ['Required'],
          },
        }),
        422,
      );
    }
    if (endpoint == 'files' && request.method == 'POST') {
      return http.Response('{"message":"Demo upload accepted"}', 201);
    }
    return http.Response('{"message":"Demo endpoint not found"}', 404);
  });
}
