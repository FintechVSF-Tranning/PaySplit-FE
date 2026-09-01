import 'package:flutter/widgets.dart';

enum CameraLifecycleAction { none, release, reinitialize }

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
