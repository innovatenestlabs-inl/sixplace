import 'dart:typed_data';

/// A successful HTTP response and optional application-decoded data.
class SPNetworkResponse<T> {
  /// Creates a response, defensively copying headers and bytes.
  SPNetworkResponse({
    required this.data,
    required this.statusCode,
    required this.uri,
    required Map<String, String> headers,
    required List<int> bodyBytes,
    required this.attempts,
  }) : headers = Map.unmodifiable(headers),
       bodyBytes = Uint8List.fromList(bodyBytes).asUnmodifiableView();

  /// Decoded content. Empty bodies, HEAD, 204, and 205 produce null.
  final T? data;

  /// Successful HTTP status (200 through 299).
  final int statusCode;

  /// Original requested URL.
  final Uri uri;

  /// Unmodifiable response headers.
  final Map<String, String> headers;

  /// Unmodifiable, buffered response bytes.
  final Uint8List bodyBytes;

  /// Number of transport attempts, including the first one.
  final int attempts;
}
