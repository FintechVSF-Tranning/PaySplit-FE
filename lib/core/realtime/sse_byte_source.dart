export 'sse_byte_source_stub.dart'
    if (dart.library.io) 'sse_byte_source_io.dart'
    if (dart.library.js_interop) 'sse_byte_source_web.dart';
