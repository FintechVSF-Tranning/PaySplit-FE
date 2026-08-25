import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Đại diện cho 1 ảnh hoá đơn đã chụp hoặc chọn từ thư viện.
class CapturedBillPhoto {
  final String id;
  final XFile file;
  final Uint8List bytes;
  final String name;
  final int sizeBytes;
  final DateTime capturedAt;
  final int rotationQuarterTurns;

  const CapturedBillPhoto({
    required this.id,
    required this.file,
    required this.bytes,
    required this.name,
    required this.sizeBytes,
    required this.capturedAt,
    this.rotationQuarterTurns = 0,
  });

  CapturedBillPhoto copyWith({
    String? id,
    XFile? file,
    Uint8List? bytes,
    String? name,
    int? sizeBytes,
    DateTime? capturedAt,
    int? rotationQuarterTurns,
  }) {
    return CapturedBillPhoto(
      id: id ?? this.id,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
    );
  }
}
