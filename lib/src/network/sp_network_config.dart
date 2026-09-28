import 'dart:async';

import 'sp_network_exception.dart';
import 'sp_retry_policy.dart';

/// Reads the current bearer token without tying Sixplace to a storage package.
typedef SPTokenProvider = FutureOr<String?> Function();

/// App-owned cleanup/navigation after an authenticated HTTP 401.
typedef SPUnauthorizedHandler =
    FutureOr<void> Function(SPNetworkException error);

/// Receives sanitized metadata only; no URL paths, queries, headers or bodies.
typedef SPNetworkLogger = void Function(SPNetworkLog event);

/// Safe request lifecycle metadata. Logging is opt-in.
class SPNetworkLog {
  /// Creates a diagnostic event.
  const SPNetworkLog({
    required this.phase,
    required this.method,
    required this.attempt,
    this.statusCode,
    this.errorType,
  });

  /// One of request, response, retry, error, or unauthorizedCallbackError.
  final String phase;

  /// Uppercase HTTP method.
  final String method;

  /// One-based attempt index.
  final int attempt;

  /// HTTP status, when known.
  final int? statusCode;

  /// Classified failure, when known.
  final SPNetworkErrorType? errorType;

  @override
  String toString() =>
      'SPNetwork $phase $method attempt=$attempt '
      'status=$statusCode error=${errorType?.name}';
}

/// Validated, immutable configuration for one backend.
class SPNetworkConfig {
  /// Creates a backend configuration with a directory-style base URL.
  ///
  /// Both `https://example.com/api/v2` and the trailing-slash variant keep the
  /// `/api/v2/` prefix. Use a separate client for a different origin.
  SPNetworkConfig({
    required String baseUrl,
    Map<String, String> headers = const {},
    this.timeout = const Duration(seconds: 30),
    SPRetryPolicy? retryPolicy,
    this.tokenProvider,
    this.onUnauthorized,
    this.logger,
    this.maxResponseBytes = 20 * 1024 * 1024,
  }) : baseUri = _validateBaseUrl(baseUrl),
       headers = Map.unmodifiable(headers),
       retryPolicy = retryPolicy ?? SPRetryPolicy() {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    if (maxResponseBytes <= 0) {
      throw ArgumentError.value(maxResponseBytes, 'maxResponseBytes');
    }
  }

  /// Normalized absolute HTTP(S) base directory.
  final Uri baseUri;

  /// Default headers. Avoid storing bearer tokens here; use [tokenProvider].
  final Map<String, String> headers;

  /// Deadline for each send plus full body read, also used for async hooks.
  final Duration timeout;

  /// Retry configuration. Writes are always sent at most once.
  final SPRetryPolicy retryPolicy;

  /// Evaluated at call time so newly saved tokens take effect immediately.
  final SPTokenProvider? tokenProvider;

  /// Called once per auth session for a token-bearing request returning 401.
  /// Call the client's resetUnauthorizedState after a successful new login.
  final SPUnauthorizedHandler? onUnauthorized;

  /// Optional safe diagnostic sink. Exceptions in this sink are ignored.
  final SPNetworkLogger? logger;

  /// Buffered response limit; streaming large downloads is not supported.
  final int maxResponseBytes;

  static Uri _validateBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'baseUrl must be an absolute HTTP(S) URL without '
        'credentials, query, or fragment.',
      );
    }
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
}
