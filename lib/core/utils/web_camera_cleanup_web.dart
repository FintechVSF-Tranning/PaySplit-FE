import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> stopWebCameraTracksImpl() async {
  final videos = web.document.querySelectorAll('video');

  for (var index = 0; index < videos.length; index++) {
    final element = videos.item(index);
    if (!element.isA<web.HTMLVideoElement>()) continue;

    final video = element as web.HTMLVideoElement;
    if (video.srcObject == null) continue;

    final stream = video.srcObject! as web.MediaStream;
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }

    video
      ..pause()
      ..srcObject = null;
  }
}
