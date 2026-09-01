class CameraOperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> schedule(Future<void> Function() operation) {
    final Future<void> next = _tail.then<void>((_) => operation());
    _tail = next.onError((Object _, StackTrace _) {});
    return next;
  }
}
