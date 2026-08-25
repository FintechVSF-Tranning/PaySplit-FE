import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Mã QR **thật, quét được** cho lời mời vào nhóm.
///
/// Nội dung mã hóa chính là `invite_url` do backend cấp (ví dụ
/// `https://paysplit.app/join/xuRWai09`). Backend không sinh ảnh QR cho lời
/// mời — nó chỉ trả chuỗi URL, việc dựng hình là của client. (Khác với QR
/// thanh toán VietQR: cái đó backend sinh sẵn `qr_image_url`.)
class InviteQrCode extends StatelessWidget {
  const InviteQrCode({
    super.key,
    required this.data,
    this.size = 220,
    this.foreground = const Color(0xFF0F172A),
    this.centerLabel,
  });

  final String data;
  final double size;
  final Color foreground;

  /// Chữ viết tắt của nhóm đặt giữa mã, giống logo overlay của VietQR.
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      size: size,
      // Mức sửa lỗi H cho phép che tới 30% diện tích mã, đủ để đặt nhãn ở giữa
      // mà máy quét vẫn đọc được.
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      backgroundColor: Colors.white,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foreground),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foreground,
      ),
      padding: EdgeInsets.all(size * 0.04),
    );
  }
}

/// Bọc [InviteQrCode] kèm nhãn tròn ở giữa.
class InviteQrCodeWithLabel extends StatelessWidget {
  const InviteQrCodeWithLabel({
    super.key,
    required this.data,
    this.size = 220,
    this.foreground = const Color(0xFF0F172A),
    this.centerLabel,
  });

  final String data;
  final double size;
  final Color foreground;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InviteQrCode(data: data, size: size, foreground: foreground),
          if (centerLabel != null)
            Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.06),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                centerLabel!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
