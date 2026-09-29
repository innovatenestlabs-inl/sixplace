/// Stable categories for application-specific messages and recovery.
enum SPNetworkErrorType {
  /// The server returned a non-2xx status.
  http,

  /// Token lookup failed (not an HTTP 401).
  authentication,

  /// The configured timeout expired, including while downloading a body.
  timeout,

  /// Transport failure, including DNS, TLS, offline, or browser CORS failures.
  connection,

  /// Caller cancellation or client shutdown.
  cancelled,

  /// A successful response could not be decoded or mapped to the model.
  decoding,

  /// The buffered response exceeded the configured byte limit.
  responseTooLarge,
}

/// A typed failure without navigation, storage, or UI side effects.
///
/// [cause], [uri], [body], and [headers] can contain sensitive information.
/// They are deliberately excluded from [toString]. Never log them blindly.
class SPNetworkException implements Exception {
  /// Creates a network failure.
  const SPNetworkException({
    required this.type,
    required this.message,
    required this.method,
    required this.uri,
    this.statusCode,
    this.body,
    this.headers = const {},
    this.cause,
    this.stackTrace,
    this.attempt = 1,
  });

  /// Machine-readable failure classification.
  final SPNetworkErrorType type;

  /// A safe default description; apps may localize it by [type].
  final String message;

  /// Uppercase HTTP method.
  final String method;

  /// Requested URL. May contain private query parameters.
  final Uri uri;

  /// HTTP status, when a response was received.
  final int? statusCode;

  /// Error body, decoded as JSON when possible, otherwise text.
  final Object? body;

  /// Response headers. May include cookies or other private values.
  final Map<String, String> headers;

  /// Original transport, provider, or decoder error, when available.
  final Object? cause;

  /// Stack trace associated with [cause].
  final StackTrace? stackTrace;

  /// One-based transport attempt number.
  final int attempt;

  @override
  String toString() =>
      'SPNetworkException(${type.name}, '
      'status: $statusCode, attempt: $attempt)';
}
