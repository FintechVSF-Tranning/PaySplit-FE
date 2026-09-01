import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/camera_operation_queue.dart';
import 'package:paysplit/features/bills/presentation/camera_lifecycle.dart';

void main() {
  group('cameraLifecycleAction', () {
    test('releases camera when the app leaves the foreground', () {
      expect(
        cameraLifecycleAction(AppLifecycleState.inactive),
        CameraLifecycleAction.release,
      );
      expect(
        cameraLifecycleAction(AppLifecycleState.hidden),
        CameraLifecycleAction.release,
      );
      expect(
        cameraLifecycleAction(AppLifecycleState.paused),
        CameraLifecycleAction.release,
      );
    });

    test('reinitializes camera on resume even after a prior release', () {
      expect(
        cameraLifecycleAction(AppLifecycleState.resumed),
        CameraLifecycleAction.reinitialize,
      );
    });

    test('ignores detached', () {
      expect(
        cameraLifecycleAction(AppLifecycleState.detached),
        CameraLifecycleAction.none,
      );
    });

    test('ignores focus loss on web while permission dialog is open', () {
      expect(
        cameraLifecycleAction(AppLifecycleState.inactive, isWeb: true),
        CameraLifecycleAction.none,
      );
      expect(
        cameraLifecycleAction(AppLifecycleState.hidden, isWeb: true),
        CameraLifecycleAction.release,
      );
    });

    test('web resumes only after lifecycle released the camera', () {
      expect(
        shouldReinitializeCamera(isWeb: true, wasReleasedByLifecycle: false),
        isFalse,
      );
      expect(
        shouldReinitializeCamera(isWeb: true, wasReleasedByLifecycle: true),
        isTrue,
      );
      expect(
        shouldReinitializeCamera(isWeb: false, wasReleasedByLifecycle: false),
        isTrue,
      );
    });
  });

  group('CameraOperationQueue', () {
    test('waits for an in progress initialize before releasing', () async {
      final queue = CameraOperationQueue();
      final initializeStarted = Completer<void>();
      final allowInitializeToFinish = Completer<void>();
      final events = <String>[];

      final initialize = queue.schedule(() async {
        events.add('initialize start');
        initializeStarted.complete();
        await allowInitializeToFinish.future;
        events.add('initialize end');
      });
      await initializeStarted.future;

      final release = queue.schedule(() async {
        events.add('release');
      });

      await Future<void>.delayed(Duration.zero);
      expect(events, <String>['initialize start']);

      allowInitializeToFinish.complete();
      await Future.wait(<Future<void>>[initialize, release]);
      expect(events, <String>['initialize start', 'initialize end', 'release']);
    });

    test('continues with resume after pause release completes', () async {
      final queue = CameraOperationQueue();
      final events = <String>[];

      await Future.wait(<Future<void>>[
        queue.schedule(() async => events.add('initial initialize')),
        queue.schedule(() async => events.add('pause release')),
        queue.schedule(() async => events.add('resume initialize')),
      ]);

      expect(events, <String>[
        'initial initialize',
        'pause release',
        'resume initialize',
      ]);
    });

    test('continues after a failed camera operation', () async {
      final queue = CameraOperationQueue();
      var resumed = false;

      final failed = queue.schedule(() async {
        throw StateError('initialize failed');
      });
      await expectLater(failed, throwsStateError);

      await queue.schedule(() async {
        resumed = true;
      });
      expect(resumed, isTrue);
    });
  });
}
