import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Kết quả giải mã một ảnh QR.
sealed class QrDecodeResult {
  const QrDecodeResult();
}

class QrDecodeSuccess extends QrDecodeResult {
  const QrDecodeSuccess(this.text);

  /// Chuỗi nằm trong mã, với lời mời nhóm là `invite_url`.
  final String text;
}

class QrDecodeFailure extends QrDecodeResult {
  const QrDecodeFailure(this.message);

  final String message;
}

/// Giải mã QR từ **bytes ảnh** (PNG/JPEG) hoàn toàn bằng Dart thuần.
///
/// Dùng `zxing2` + `image` thay vì máy quét gắn với nền tảng vì cách này chạy
/// được ở mọi nơi kể cả Flutter Web — nơi các thư viện camera thường không ổn
/// định. Nhờ vậy có thể thử luồng vào nhóm bằng ảnh QR ngay trên trình duyệt,
/// không cần thiết bị thật.
QrDecodeResult decodeQrFromImageBytes(Uint8List bytes) {
  // decodeImage ném exception (không trả null) khi bytes không phải ảnh hợp lệ,
  // ví dụ người dùng chọn nhầm tệp hỏng — phải bắt, nếu không app sẽ vỡ.
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return const QrDecodeFailure('Không đọc được tệp ảnh. Hãy chọn ảnh PNG hoặc JPG.');
  }
  if (decoded == null) {
    return const QrDecodeFailure('Không đọc được tệp ảnh. Hãy chọn ảnh PNG hoặc JPG.');
  }

  // zxing2 cần luminance dạng int32 ARGB theo hàng.
  final pixels = Int32List(decoded.width * decoded.height);
  var index = 0;
  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      pixels[index++] =
          (0xFF << 24) | (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
    }
  }

  final source = RGBLuminanceSource(decoded.width, decoded.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));

  try {
    final result = QRCodeReader().decode(bitmap);
    return QrDecodeSuccess(result.text);
  } on NotFoundException {
    return const QrDecodeFailure('Không tìm thấy mã QR trong ảnh. Hãy chọn ảnh rõ nét hơn.');
  } on FormatReaderException {
    return const QrDecodeFailure('Mã QR trong ảnh bị lỗi định dạng.');
  } on ChecksumException {
    return const QrDecodeFailure('Mã QR trong ảnh bị hỏng, không đọc được.');
  }
}
