/// A token that can be passed to operations to allow them to be cancelled.
class CancellationToken {
  bool _isCancelled = false;

  /// Whether the cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Cancels the operation associated with this token.
  void cancel() {
    _isCancelled = true;
  }
}
