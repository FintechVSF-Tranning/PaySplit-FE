import 'dart:typed_data';

/// Bộ kiểm tra định dạng và tính hợp lệ của file ảnh trước khi xử lý hoặc upload.
class ImageValidator {
  ImageValidator._();

  /// Giới hạn dung lượng tối đa cho mỗi ảnh hoá đơn (10 MB theo chuẩn Backend & OCR).
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  /// Các phần mở rộng tệp ảnh hợp lệ.
  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  /// Kiểm tra Magic Bytes / File Signatures thực tế của mảng bytes.
  /// Ngăn chặn người dùng đổi đuôi file giả mạo (ví dụ: .exe, .elf, .pdf đổi tên thành .jpg).
  static bool isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // 1. JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // 2. PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    // 3. WebP: "RIFF" .... "WEBP"
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    // 4. HEIC / HEIF: bytes 4..8 là "ftyp"
    if (bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
      if (brand.startsWith('hei') ||
          brand.startsWith('mif1') ||
          brand.startsWith('msf1') ||
          brand.startsWith('hevc')) {
        return true;
      }
    }

    return false;
  }

  /// Kiểm tra toàn diện 1 tệp ảnh: Dung lượng & Định dạng Magic Bytes.
  /// Trả về `null` nếu hợp lệ, hoặc chuỗi thông báo lỗi cụ thể nếu không hợp lệ.
  static String? validateImage({
    required Uint8List bytes,
    required String fileName,
    int maxBytes = maxImageSizeBytes,
  }) {
    if (bytes.isEmpty) {
      return 'Tệp "$fileName" bị rỗng (0 bytes).';
    }

    if (bytes.lengthInBytes > maxBytes) {
      final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'Ảnh "$fileName" vượt quá dung lượng tối đa cho phép (${mb}MB).';
    }

    if (!isValidImageBytes(bytes)) {
      return 'Tệp "$fileName" không đúng định dạng ảnh hợp lệ (chỉ hỗ trợ JPG, PNG, WebP, HEIC).';
    }

    return null;
  }
}
