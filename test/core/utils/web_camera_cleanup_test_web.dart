import 'dart:js_interop';

import 'package:paysplit/core/utils/web_camera_cleanup.dart';
import 'package:web/web.dart' as web;

Future<bool> verifyWebCameraCleanup() async {
  final stream = await web.window.navigator.mediaDevices
      .getUserMedia(
        web.MediaStreamConstraints(video: true.toJS, audio: false.toJS),
      )
      .toDart;
  final track = stream.getVideoTracks().toDart.single;
  final video = web.HTMLVideoElement()..srcObject = stream;
  web.document.body!.append(video);

  try {
    if (track.readyState != 'live') return false;
    await stopWebCameraTracks();
    return track.readyState == 'ended' && video.srcObject == null;
  } finally {
    track.stop();
    video.remove();
  }
}
