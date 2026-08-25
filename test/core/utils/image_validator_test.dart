import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/image_validator.dart';

void main() {
  group('ImageValidator Unit Tests', () {
    test('detects valid PNG bytes', () {
      final pngBytes = Uint8List.fromList(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      ]);
      expect(ImageValidator.isValidImageBytes(pngBytes), isTrue);
      expect(ImageValidator.validateImage(bytes: pngBytes, fileName: 'test.png'), isNull);
    });

    test('detects valid JPEG bytes', () {
      final jpegBytes = Uint8List.fromList(<int>[
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      ]);
      expect(ImageValidator.isValidImageBytes(jpegBytes), isTrue);
      expect(ImageValidator.validateImage(bytes: jpegBytes, fileName: 'test.jpg'), isNull);
    });

    test('detects valid WebP bytes', () {
      final webpBytes = Uint8List.fromList(<int>[
        0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
      ]);
      expect(ImageValidator.isValidImageBytes(webpBytes), isTrue);
      expect(ImageValidator.validateImage(bytes: webpBytes, fileName: 'test.webp'), isNull);
    });

    test('rejects invalid binary/ELF file header', () {
      // ELF magic bytes: 0x7F 'E' 'L' 'F' ...
      final elfBytes = Uint8List.fromList(<int>[
        0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);
      expect(ImageValidator.isValidImageBytes(elfBytes), isFalse);
      final err = ImageValidator.validateImage(bytes: elfBytes, fileName: 'binary_file.jpg');
      expect(err, contains('không đúng định dạng ảnh hợp lệ'));
    });

    test('rejects empty byte array', () {
      final emptyBytes = Uint8List(0);
      final err = ImageValidator.validateImage(bytes: emptyBytes, fileName: 'empty.png');
      expect(err, contains('bị rỗng'));
    });

    test('rejects oversized image', () {
      final oversizedBytes = Uint8List(11 * 1024 * 1024);
      final err = ImageValidator.validateImage(bytes: oversizedBytes, fileName: 'large.jpg');
      expect(err, contains('vượt quá dung lượng tối đa'));
    });
  });
}
