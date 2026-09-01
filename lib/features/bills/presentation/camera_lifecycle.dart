import 'package:flutter/widgets.dart';

enum CameraLifecycleAction { none, release, reinitialize }

class CameraOperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> schedule(Future<void> Function() operation) {
    final Future<void> next = _tail.then<void>((_) => operation());
    _tail = next.onError((Object _, StackTrace _) {});
    return next;
  }
}

CameraLifecycleAction cameraLifecycleAction(
  AppLifecycleState state, {
  bool isWeb = false,
}) {
  switch (state) {
    case AppLifecycleState.inactive:
      return isWeb ? CameraLifecycleAction.none : CameraLifecycleAction.release;
    case AppLifecycleState.hidden:
    case AppLifecycleState.paused:
      return CameraLifecycleAction.release;
    case AppLifecycleState.resumed:
      return CameraLifecycleAction.reinitialize;
    case AppLifecycleState.detached:
      return CameraLifecycleAction.none;
  }
}

bool shouldReinitializeCamera({
  required bool isWeb,
  required bool wasReleasedByLifecycle,
}) => !isWeb || wasReleasedByLifecycle;
