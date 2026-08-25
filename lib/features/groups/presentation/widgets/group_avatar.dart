import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/group_entity.dart';

/// Avatar nhóm: chữ viết tắt của tên nhóm trên nền màu.
///
/// Màu nền lấy từ [GroupEntity.id] nên cố định theo nhóm và **giống nhau trên
/// mọi thiết bị và mọi thành viên** — id do backend cấp và không đổi. Nhờ vậy
/// các nhóm cùng viết tắt (ví dụ "Du lịch tháng 9" và "Du lịch tháng 10" đều ra
/// "DL") vẫn phân biệt được bằng mắt.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.group,
    this.size = 46,
    this.shape = BoxShape.rectangle,
    this.muted = false,
  });

  final GroupEntity group;
  final double size;
  final BoxShape shape;

  /// Làm mờ cho nhóm đã khóa bill.
  final bool muted;

  /// Bảng màu avatar. Dùng chỉ số ổn định từ id thay vì `hashCode` của chuỗi vì
  /// `String.hashCode` không được đảm bảo giống nhau giữa các lần chạy.
  static const List<(Color background, Color border, Color foreground)> _palette = [
    (Color(0xFFE0F2F1), Color(0xFFB2DFDB), Color(0xFF00796B)),
    (Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF1565C0)),
    (Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFE65100)),
    (Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFF6A1B9A)),
    (Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFF2E7D32)),
    (Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFAD1457)),
  ];

  static (Color, Color, Color) paletteFor(String groupId) {
    var sum = 0;
    for (var i = 0; i < groupId.length; i++) {
      sum = (sum + groupId.codeUnitAt(i)) % 100000;
    }
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = muted
        ? (AppColors.surfaceMuted, AppColors.border, AppColors.textMuted)
        : paletteFor(group.id);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(size * 0.3) : null,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        group.initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
