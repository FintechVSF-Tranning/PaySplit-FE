import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_camera_cleanup_test_stub.dart'
    if (dart.library.js_interop) 'web_camera_cleanup_test_web.dart';

void main() {
  test(
    'stops every live video track attached to the page',
    () async {
      expect(await verifyWebCameraCleanup(), isTrue);
    },
    skip: !kIsWeb,
  );
}
