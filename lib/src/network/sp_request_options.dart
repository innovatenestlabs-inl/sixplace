import 'sp_cancel_token.dart';
import 'sp_retry_policy.dart';

/// Successful response decoding strategy.
enum SPResponseType {
  /// UTF-8 JSON; the default. Does not require a correct server content type.
  json,

  /// Text, using the server-declared charset or UTF-8 when absent.
  text,

  /// Raw bytes, for example a small PDF or spreadsheet download.
  bytes,
}

/// Per-call overrides; mutable maps are copied when the call starts.
class SPRequestOptions {
  /// Creates request options.
  const SPRequestOptions({
    this.headers = const {},
    this.authenticated = true,
    this.token,
    this.timeout,
    this.retryPolicy,
    this.responseType = SPResponseType.json,
    this.cancelToken,
  });

  /// Extra headers, overriding global headers case-insensitively.
  final Map<String, String> headers;

  /// False removes Authorization and skips token lookup and the 401 hook.
  ///
  /// Use for login/registration. Browser-managed cookies are not controlled.
  final bool authenticated;

  /// Optional bearer token override. Empty string explicitly omits bearer auth.
  /// Null uses the configured token provider or explicit Authorization header.
  final String? token;

  /// Per-attempt timeout through body completion; must be positive.
  final Duration? timeout;

  /// Overrides the configured read-request retry policy.
  final SPRetryPolicy? retryPolicy;

  /// How to decode a successful body before invoking a model decoder.
  final SPResponseType responseType;

  /// Optional cancellation shared by one or more calls.
  final SPCancelToken? cancelToken;
}
