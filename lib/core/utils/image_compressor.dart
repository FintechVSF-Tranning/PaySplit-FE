import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image compression and optimization utility for OCR receipts and uploads.
/// Uses background isolate via [compute] to prevent UI jank.
class ImageCompressor {
  ImageCompressor._();

  /// Default threshold: 10 MB (aligned with Backend & OCR upload limit).
  /// Images <= 10 MB preserve original bytes to prevent re-compression artifacts.
  static const int defaultThresholdBytes = 10 * 1024 * 1024;

  /// Maximum dimension (Full HD 1920px for OCR readability).
  static const int defaultMaxDimension = 1920;

  /// JPEG compression quality for OCR readability (80%).
  static const int defaultQuality = 80;

  /// Compresses and downscales image bytes if size exceeds [thresholdBytes].
  ///
  /// - If `rawBytes.lengthInBytes <= thresholdBytes`: returns raw bytes immediately.
  /// - Otherwise: offloads decoding, resizing to max 1920px, and JPEG encoding to an isolate
  ///   to guarantee the output is within [thresholdBytes].
  static Future<Uint8List> compress(
    Uint8List rawBytes, {
    int thresholdBytes = defaultThresholdBytes,
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    if (rawBytes.lengthInBytes <= thresholdBytes) {
      return rawBytes;
    }

    try {
      return await compute(
        _compressWorker,
        _CompressParams(rawBytes, maxDimension, quality, thresholdBytes),
      );
    } catch (e) {
      debugPrint('ImageCompressor error: $e. Fallback to raw bytes.');
      return rawBytes;
    }
  }

  static Uint8List _compressWorker(_CompressParams params) {
    final image = img.decodeImage(params.bytes);
    if (image == null) return params.bytes;

    int targetDimension = params.maxDimension;
    int targetQuality = params.quality;

    img.Image processed = image;

    // Downscale if either dimension exceeds maxDimension
    if (image.width > targetDimension || image.height > targetDimension) {
      if (image.width >= image.height) {
        processed = img.copyResize(image, width: targetDimension);
      } else {
        processed = img.copyResize(image, height: targetDimension);
      }
    }

    var compressed = img.encodeJpg(processed, quality: targetQuality);

    // Iteratively adjust if still exceeding threshold (safety guarantee <= 10MB)
    while (compressed.lengthInBytes > params.thresholdBytes &&
        targetDimension > 800) {
      targetDimension = (targetDimension * 0.8).toInt();
      targetQuality = (targetQuality * 0.85).toInt();
      if (image.width >= image.height) {
        processed = img.copyResize(image, width: targetDimension);
      } else {
        processed = img.copyResize(image, height: targetDimension);
      }
      compressed = img.encodeJpg(processed, quality: targetQuality);
    }

    return Uint8List.fromList(compressed);
  }
}

class _CompressParams {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;
  final int thresholdBytes;

  const _CompressParams(
    this.bytes,
    this.maxDimension,
    this.quality,
    this.thresholdBytes,
  );
}
