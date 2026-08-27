import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Đại diện cho 1 ảnh hoá đơn đã chụp/chọn từ thư viện (offline) hoặc tải từ Cloudinary (online).
class CapturedBillPhoto {
  final String id;
  final XFile? file;
  final Uint8List? bytes;
  final String? url;
  final String name;
  final int sizeBytes;
  final DateTime capturedAt;
  final int rotationQuarterTurns;

  const CapturedBillPhoto({
    required this.id,
    this.file,
    this.bytes,
    this.url,
    required this.name,
    this.sizeBytes = 0,
    required this.capturedAt,
    this.rotationQuarterTurns = 0,
  });

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasUrl => url != null && url!.isNotEmpty;

  CapturedBillPhoto copyWith({
    String? id,
    XFile? file,
    Uint8List? bytes,
    String? url,
    String? name,
    int? sizeBytes,
    DateTime? capturedAt,
    int? rotationQuarterTurns,
  }) {
    return CapturedBillPhoto(
      id: id ?? this.id,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      url: url ?? this.url,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
    );
  }
}
