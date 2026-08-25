import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paysplit/features/groups/data/qr_image_decoder.dart';
import 'package:paysplit/features/groups/domain/invite_code.dart';
import 'package:qr/qr.dart';

/// Vẽ QR ra ảnh PNG bằng cùng thư viện `qr` mà `qr_flutter` dùng bên dưới, để
/// kiểm tra vòng tròn khép kín: sinh mã -> ảnh -> giải mã -> tách mã mời.
Uint8List _renderQrPng(String data, {int scale = 8, int quiet = 4}) {
  final code = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.H);
  final matrix = QrImage(code);
  final modules = code.moduleCount;
  final side = (modules + quiet * 2) * scale;

  final image = img.Image(width: side, height: side);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  for (var row = 0; row < modules; row++) {
    for (var col = 0; col < modules; col++) {
      if (!matrix.isDark(row, col)) continue;
      img.fillRect(
        image,
        x1: (col + quiet) * scale,
        y1: (row + quiet) * scale,
        x2: (col + quiet + 1) * scale - 1,
        y2: (row + quiet + 1) * scale - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('QR mời vào nhóm — vòng tròn khép kín', () {
    // pt1sRukj là mã mời thật lấy từ cơ sở dữ liệu phát triển.
    const inviteUrl = 'https://paysplit.app/join/pt1sRukj';

    test('QR sinh ra giải mã lại đúng invite_url', () {
      final png = _renderQrPng(inviteUrl);
      final result = decodeQrFromImageBytes(png);

      expect(result, isA<QrDecodeSuccess>());
      expect((result as QrDecodeSuccess).text, inviteUrl);
    });

    test('mã mời tách ra từ QR giữ nguyên hoa thường', () {
      final png = _renderQrPng(inviteUrl);
      final decoded = decodeQrFromImageBytes(png) as QrDecodeSuccess;

      final code = extractInviteCode(decoded.text);
      expect(code, 'pt1sRukj');
      expect(code.length, kInviteCodeLength);
    });

    test('ảnh không chứa QR báo lỗi thay vì ném exception', () {
      final blank = img.Image(width: 120, height: 120);
      img.fill(blank, color: img.ColorRgb8(255, 255, 255));
      final result = decodeQrFromImageBytes(Uint8List.fromList(img.encodePng(blank)));

      expect(result, isA<QrDecodeFailure>());
    });

    test('bytes không phải ảnh báo lỗi rõ ràng', () {
      final result = decodeQrFromImageBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(result, isA<QrDecodeFailure>());
      expect((result as QrDecodeFailure).message, contains('ảnh'));
    });
  });
}
