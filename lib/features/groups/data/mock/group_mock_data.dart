import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';

/// Dữ liệu mocup phục vụ dựng UI luồng Nhóm trước khi nối API thật.
/// Khi backend sẵn sàng, thay lớp này bằng `GroupRemoteDataSource` + repository.
abstract class GroupMockData {
  static final DateTime _now = DateTime(2026, 8, 24, 20, 30);

  /// Biểu tượng đại diện cho nhóm, dùng chung ở sheet tạo nhóm.
  static const List<GroupEmojiOption> emojiOptions = [
    GroupEmojiOption(emoji: '🌴', label: 'Du lịch'),
    GroupEmojiOption(emoji: '🍜', label: 'Cơm trưa'),
    GroupEmojiOption(emoji: '🍻', label: 'Ăn uống'),
    GroupEmojiOption(emoji: '☕', label: 'Cafe'),
    GroupEmojiOption(emoji: '🏠', label: 'Trọ'),
    GroupEmojiOption(emoji: '🎬', label: 'Giải trí'),
    GroupEmojiOption(emoji: '🚗', label: 'Di chuyển'),
    GroupEmojiOption(emoji: '🎁', label: 'Quà tặng'),
  ];

  static List<GroupEntity> get myGroups => [
    GroupEntity(
      id: 'g_001',
      name: 'Du lịch Đà Lạt 2026',
      emoji: '🌴',
      memberCount: 5,
      myBalance: -340000,
      inviteCode: 'DALAT2026',
      isCaptain: false,
      lastActivity: 'Nam vừa thêm hóa đơn Lẩu gà lá é',
      lastActivityAt: _now.subtract(const Duration(minutes: 25)),
      pendingBillCount: 3,
    ),
    GroupEntity(
      id: 'g_002',
      name: 'Cơm trưa văn phòng',
      emoji: '🍜',
      memberCount: 8,
      myBalance: 185000,
      inviteCode: 'LUNCH88',
      isCaptain: true,
      lastActivity: 'Bạn đã chốt chia tiền hóa đơn Bún bò Huế',
      lastActivityAt: _now.subtract(const Duration(hours: 5)),
      pendingBillCount: 1,
    ),
    GroupEntity(
      id: 'g_003',
      name: 'Nhà trọ Quận 7',
      emoji: '🏠',
      memberCount: 4,
      myBalance: 0,
      inviteCode: 'TROQ7X',
      isCaptain: true,
      lastActivity: 'Tất cả đã thanh toán tiền điện tháng 8',
      lastActivityAt: _now.subtract(const Duration(days: 2)),
    ),
    GroupEntity(
      id: 'g_004',
      name: 'Team Building Vũng Tàu',
      emoji: '🍻',
      memberCount: 12,
      myBalance: -1250000,
      inviteCode: 'VTAU26',
      isCaptain: false,
      lastActivity: 'Linh đã nộp minh chứng chuyển khoản',
      lastActivityAt: _now.subtract(const Duration(days: 4)),
      pendingBillCount: 2,
    ),
    GroupEntity(
      id: 'g_005',
      name: 'Sinh nhật Trâm Anh',
      emoji: '🎁',
      memberCount: 6,
      myBalance: -150000,
      inviteCode: 'BDAYTA',
      isCaptain: false,
      lastActivity: 'Nhóm đã khóa bill, bạn còn 1 khoản cần trả',
      lastActivityAt: _now.subtract(const Duration(days: 21)),
      status: GroupStatus.closed,
      closedAtText: '03/08/2026',
    ),
    GroupEntity(
      id: 'g_006',
      name: 'Du lịch Phú Quốc 2025',
      emoji: '🌴',
      memberCount: 9,
      myBalance: 0,
      inviteCode: 'PQUOC25',
      isCaptain: true,
      lastActivity: 'Bạn đã khóa bill nhóm, mọi người đã tất toán',
      lastActivityAt: _now.subtract(const Duration(days: 96)),
      status: GroupStatus.closed,
      closedAtText: '20/05/2026',
    ),
  ];

  /// Nhóm đã tham gia/ghé thăm gần đây — hiển thị dạng hàng ngang gọn.
  static List<GroupEntity> get recentGroups => [myGroups[0], myGroups[1], myGroups[4]];

  /// Danh bạ gợi ý khi thêm thành viên vào nhóm vừa tạo.
  static const List<GroupMemberEntity> recentContacts = [
    GroupMemberEntity(
      id: 'u_101',
      name: 'Trần Hoàng Nam',
      phone: '0901 234 567',
      sharedGroupCount: 4,
    ),
    GroupMemberEntity(
      id: 'u_102',
      name: 'Nguyễn Thùy Linh',
      phone: '0912 888 121',
      sharedGroupCount: 3,
    ),
    GroupMemberEntity(
      id: 'u_103',
      name: 'Phạm Minh Tuấn',
      phone: '0987 654 321',
      sharedGroupCount: 3,
    ),
    GroupMemberEntity(id: 'u_104', name: 'Lê Trâm Anh', phone: '0938 445 902', sharedGroupCount: 2),
    GroupMemberEntity(id: 'u_105', name: 'Võ Quốc Bảo', phone: '0977 310 654', sharedGroupCount: 1),
    GroupMemberEntity(
      id: 'u_106',
      name: 'Đặng Khánh Vy',
      phone: '0964 227 118',
      sharedGroupCount: 1,
    ),
  ];
}

class GroupEmojiOption {
  const GroupEmojiOption({required this.emoji, required this.label});

  final String emoji;
  final String label;
}
