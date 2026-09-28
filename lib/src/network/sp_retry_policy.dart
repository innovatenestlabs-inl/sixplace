import 'dart:math' as math;

/// Bounded exponential retries for GET and HEAD only.
///
/// Sixplace's retry loop never retries writes, even when an idempotency header
/// is supplied. An injected custom HTTP client may have its own replay policy.
/// [maxAttempts] includes the initial request, not just retries.
class SPRetryPolicy {
  /// Creates a policy. Two retries means [maxAttempts] is three.
  SPRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 5),
    this.multiplier = 2,
    Set<int> statusCodes = const {408, 429, 502, 503, 504},
  }) : statusCodes = Set.unmodifiable(statusCodes) {
    if (maxAttempts < 1 || maxAttempts > 10) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts', 'Use 1 to 10.');
    }
    if (initialDelay.isNegative ||
        maxDelay.isNegative ||
        maxDelay < initialDelay) {
      throw ArgumentError('Require 0 <= initialDelay <= maxDelay.');
    }
    if (!multiplier.isFinite || multiplier < 1) {
      throw ArgumentError.value(
        multiplier,
        'multiplier',
        'Must be finite >= 1.',
      );
    }
    if (statusCodes.any(
      (code) => code < 400 || code > 599 || code == 401 || code == 403,
    )) {
      throw ArgumentError('Retry statuses must be 4xx/5xx, excluding 401/403.');
    }
  }

  /// A policy that performs each request once.
  static final none = SPRetryPolicy(maxAttempts: 1);

  /// Maximum total attempts, including the first request.
  final int maxAttempts;

  /// Delay before the first retry.
  final Duration initialDelay;

  /// Maximum retry wait. Longer server Retry-After values stop retrying.
  final Duration maxDelay;

  /// Exponential backoff multiplier.
  final double multiplier;

  /// HTTP failures eligible for retry on GET/HEAD.
  final Set<int> statusCodes;

  /// Delay following the given one-based failed attempt.
  Duration delayAfter(int attempt) {
    if (attempt < 1) throw ArgumentError.value(attempt, 'attempt');
    if (initialDelay == Duration.zero) return Duration.zero;
    return Duration(
      microseconds: math
          .min(
            maxDelay.inMicroseconds.toDouble(),
            initialDelay.inMicroseconds * math.pow(multiplier, attempt - 1),
          )
          .round(),
    );
  }
}
