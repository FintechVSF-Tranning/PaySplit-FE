import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paysplit/core/utils/image_compressor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressor Tests', () {
    test('returns original bytes if image size <= thresholdBytes', () async {
      final smallBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await ImageCompressor.compress(
        smallBytes,
        thresholdBytes: 100, // 100 bytes threshold
      );

      expect(result, equals(smallBytes));
    });

    test(
      'compresses and downscales image when size > thresholdBytes',
      () async {
        // Create a 2400x2400 test image
        final largeImage = img.Image(width: 2400, height: 2400);
        for (int y = 0; y < 100; y++) {
          for (int x = 0; x < 100; x++) {
            largeImage.setPixelRgb(x, y, (x * 7) % 255, (y * 11) % 255, 128);
          }
        }
        final rawBytes = Uint8List.fromList(img.encodeJpg(largeImage));

        final result = await ImageCompressor.compress(
          rawBytes,
          thresholdBytes: 1024,
        );
        final compressedImage = img.decodeImage(result);
        expect(compressedImage, isNotNull);
        expect(compressedImage!.width, lessThanOrEqualTo(1920));
        expect(compressedImage.height, lessThanOrEqualTo(1920));
      },
    );

    test('compresses and downscales image when size > thresholdBytes', () async {
      // Create a 3000x2000 image with colorful content to produce a realistic file
      final largeImage = img.Image(width: 3000, height: 2000);
      for (int y = 0; y < 2000; y++) {
        for (int x = 0; x < 3000; x++) {
          largeImage.setPixelRgb(
            x,
            y,
            (x * 13 + y) % 256,
            (y * 17 + x) % 256,
            (x ^ y) % 256,
          );
        }
      }
      final rawBytes = Uint8List.fromList(
        img.encodeJpg(largeImage, quality: 95),
      );

      // Verify that input is > 2MB but <= 10MB
      expect(rawBytes.lengthInBytes, greaterThan(2 * 1024 * 1024));
      expect(rawBytes.lengthInBytes, lessThanOrEqualTo(10 * 1024 * 1024));

      // With default threshold (10MB), image <= 10MB is preserved without re-compression
      final preservedBytes = await ImageCompressor.compress(rawBytes);
      expect(preservedBytes, equals(rawBytes));

      // Giả lập ngưỡng 2MB để kiểm thử logic nén mà không cần sinh mảng byte > 10MB trong test runner
      const mockThreshold = 2 * 1024 * 1024;
      final stopwatch = Stopwatch()..start();
      final compressedBytes = await ImageCompressor.compress(
        rawBytes,
        thresholdBytes: mockThreshold,
      );
      stopwatch.stop();

      // Output assertions
      expect(compressedBytes.lengthInBytes, lessThan(rawBytes.lengthInBytes));
      expect(
        compressedBytes.lengthInBytes,
        lessThan(mockThreshold),
        reason: 'Compressed image should be under mock threshold',
      );
      expect(
        compressedBytes.lengthInBytes,
        lessThan(ImageCompressor.defaultThresholdBytes),
        reason: 'Compressed image should be under default 10MB limit',
      );

      final resultImage = img.decodeImage(compressedBytes);
      expect(resultImage, isNotNull);
      expect(resultImage!.width, equals(1920));
      expect(resultImage.height, equals(1280)); // 3000x2000 scaled to 1920x1280

      // Print metrics for verification
      final originalMb = (rawBytes.lengthInBytes / (1024 * 1024))
          .toStringAsFixed(2);
      final compressedKb = (compressedBytes.lengthInBytes / 1024)
          .toStringAsFixed(1);
      // ignore: avoid_print
      print(
        '=== COMPRESSION RESULT ===\n'
        'Original: $originalMb MB (3000x2000)\n'
        'Compressed: $compressedKb KB (${resultImage.width}x${resultImage.height})\n'
        'Elapsed time: ${stopwatch.elapsedMilliseconds} ms\n'
        '===============================',
      );
    });
  });
}
