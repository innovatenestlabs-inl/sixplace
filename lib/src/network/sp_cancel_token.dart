/// Cancels one request, or a group of requests sharing this token.
///
/// Cancellation is permanent. Create a new token for a new operation.
class SPCancelToken {
  final Set<void Function()> _listeners = {};
  bool _isCancelled = false;

  /// Whether [cancel] has been called.
  bool get isCancelled => _isCancelled;

  /// Requests cancellation. Repeated calls have no effect.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// Registers a synchronous listener and returns an unregister function.
  ///
  /// Listeners must not throw. Already-cancelled tokens invoke it immediately.
  void Function() addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }
}
