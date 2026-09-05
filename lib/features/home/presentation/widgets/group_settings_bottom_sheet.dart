import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

/// DTO biểu diễn thành viên nhóm hiển thị trong Modal Cài đặt nhóm
class GroupMemberSettingItem {
  final String membershipId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role; // 'captain' | 'member'
  final bool isCurrentUser;

  const GroupMemberSettingItem({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    this.isCurrentUser = false,
  });

  bool get isCaptain => role == 'captain';
}

/// Modal Bottom Sheet Quản trị và Cài đặt nhóm (Group Settings Bottom Sheet)
///
/// Tuân thủ Design System PaySplit (Slate & Deep Teal):
/// - Header: Tiêu đề "Cài đặt nhóm" căn giữa, nút 'X' góc phải để đóng
/// - 4 Section chính:
///   1. Thông tin nhóm: Monogram, Tên nhóm (có nút Đổi tên cho Captain), Tiền tệ VND, Ngày tạo
///   2. Quản trị thành viên: Nút Chuyển quyền Trưởng nhóm, Danh sách thành viên kèm nút Xóa
///   3. Trạng thái bill: Nút Khóa hóa đơn nhóm (chỉ Captain, chỉ khi mọi hóa đơn đã chia xong)
///   4. Vùng nguy hiểm (Danger Zone): Nút Rời nhóm (kiểm tra sạch nợ), Giải tán nhóm (chỉ Captain)
class GroupSettingsBottomSheet extends StatefulWidget {
  final String groupId;
  final String initialGroupName;
  final String groupCurrency;
  final String createdAtText;
  final bool isCaptain;
  final int currentUserNetBalance; // Dùng để kiểm tra sạch nợ khi rời nhóm (0đ)
  final List<GroupMemberSettingItem> members;

  /// Nhóm đã khóa nhận hóa đơn mới hay chưa.
  final bool isClosed;

  /// Ngày khóa hóa đơn, hiển thị trong thẻ trạng thái khi [isClosed].
  final String? closedAtText;

  /// Số hóa đơn còn đang chia dở; > 0 thì chưa được phép khóa hóa đơn.
  final int pendingBillCount;

  final Future<bool> Function(String newName)? onRenameGroup;
  final Future<bool> Function(String targetMembershipId)? onTransferCaptain;
  final Future<bool> Function(String targetMembershipId)? onRemoveMember;
  final Future<bool> Function()? onCloseBook;
  final Future<bool> Function()? onUnlockBook;
  final Future<bool> Function()? onLeaveGroup;
  final Future<bool> Function()? onDisbandGroup;

  const GroupSettingsBottomSheet({
    super.key,
    required this.groupId,
    required this.initialGroupName,
    this.groupCurrency = 'VND',
    required this.createdAtText,
    required this.isCaptain,
    required this.currentUserNetBalance,
    required this.members,
    this.isClosed = false,
    this.closedAtText,
    this.pendingBillCount = 0,
    this.onRenameGroup,
    this.onTransferCaptain,
    this.onRemoveMember,
    this.onCloseBook,
    this.onUnlockBook,
    this.onLeaveGroup,
    this.onDisbandGroup,
  });

  static Future<void> show({
    required BuildContext context,
    required String groupId,
    required String initialGroupName,
    String groupCurrency = 'VND',
    required String createdAtText,
    required bool isCaptain,
    required int currentUserNetBalance,
    required List<GroupMemberSettingItem> members,
    bool isClosed = false,
    String? closedAtText,
    int pendingBillCount = 0,
    Future<bool> Function(String newName)? onRenameGroup,
    Future<bool> Function(String targetMembershipId)? onTransferCaptain,
    Future<bool> Function(String targetMembershipId)? onRemoveMember,
    Future<bool> Function()? onCloseBook,
    Future<bool> Function()? onUnlockBook,
    Future<bool> Function()? onLeaveGroup,
    Future<bool> Function()? onDisbandGroup,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupSettingsBottomSheet(
        groupId: groupId,
        initialGroupName: initialGroupName,
        groupCurrency: groupCurrency,
        createdAtText: createdAtText,
        isCaptain: isCaptain,
        currentUserNetBalance: currentUserNetBalance,
        members: members,
        isClosed: isClosed,
        closedAtText: closedAtText,
        pendingBillCount: pendingBillCount,
        onRenameGroup: onRenameGroup,
        onTransferCaptain: onTransferCaptain,
        onRemoveMember: onRemoveMember,
        onCloseBook: onCloseBook,
        onUnlockBook: onUnlockBook,
        onLeaveGroup: onLeaveGroup,
        onDisbandGroup: onDisbandGroup,
      ),
    );
  }

  @override
  State<GroupSettingsBottomSheet> createState() =>
      _GroupSettingsBottomSheetState();
}

class _GroupSettingsBottomSheetState extends State<GroupSettingsBottomSheet> {
  late String _groupName;
  late List<GroupMemberSettingItem> _members;
  late bool _isCaptain;
  late bool _isClosed;
  late String? _closedAtText;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _groupName = widget.initialGroupName;
    _members = List.from(widget.members);
    _isCaptain = widget.isCaptain;
    _isClosed = widget.isClosed;
    _closedAtText = widget.closedAtText;
  }

  bool get _adminLocked => _isProcessing;

  // 1. Đổi tên nhóm
  Future<void> _handleRename() async {
    final controller = TextEditingController(text: _groupName);
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đổi tên nhóm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            maxLength: 100,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Nhập tên nhóm mới',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Tên nhóm không được để trống';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: Text(
              'Lưu thay đổi',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName != _groupName) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onRenameGroup != null
            ? await widget.onRenameGroup!(newName)
            : true;
        if (success && mounted) {
          setState(() => _groupName = newName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã đổi tên nhóm thành "$newName"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 2. Chuyển quyền Trưởng nhóm (Captain)
  Future<void> _handleTransferCaptain() async {
    final candidateMembers = _members.where((m) => !m.isCaptain).toList();
    if (candidateMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhóm chưa có thành viên khác để chuyển quyền'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    GroupMemberSettingItem? selectedMember = candidateMembers.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Chuyển quyền Trưởng nhóm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn thành viên nhận vai trò Trưởng nhóm (Captain 👑). Bạn sẽ trở thành thành viên thông thường.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GroupMemberSettingItem>(
                initialValue: selectedMember,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: candidateMembers.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedMember = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Xác nhận chuyển',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedMember != null) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onTransferCaptain != null
            ? await widget.onTransferCaptain!(selectedMember!.membershipId)
            : true;
        if (success && mounted) {
          setState(() {
            _isCaptain = false;
            _members = _members.map((m) {
              if (m.membershipId == selectedMember!.membershipId) {
                return GroupMemberSettingItem(
                  membershipId: m.membershipId,
                  userId: m.userId,
                  displayName: m.displayName,
                  role: 'captain',
                  isCurrentUser: m.isCurrentUser,
                );
              } else if (m.isCaptain) {
                return GroupMemberSettingItem(
                  membershipId: m.membershipId,
                  userId: m.userId,
                  displayName: m.displayName,
                  role: 'member',
                  isCurrentUser: m.isCurrentUser,
                );
              }
              return m;
            }).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã chuyển quyền Trưởng nhóm cho ${selectedMember!.displayName}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 3. Xóa thành viên
  Future<void> _handleRemoveMember(GroupMemberSettingItem member) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận xóa thành viên',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${member.displayName}" khỏi nhóm không?\n\nLưu ý: Thành viên này phải không còn bất kỳ khoản nợ nào trong nhóm.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Xóa thành viên',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onRemoveMember != null
            ? await widget.onRemoveMember!(member.membershipId)
            : true;
        if (success && mounted) {
          setState(() {
            _members.removeWhere((m) => m.membershipId == member.membershipId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xóa thành viên ${member.displayName} khỏi nhóm',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 4. Bật / Tắt Khóa nhận hóa đơn nhóm
  Future<void> _handleToggleLock(bool lock) async {
    if (lock) {
      await _handleCloseBook();
    } else {
      await _handleUnlockBook();
    }
  }

  Future<void> _handleCloseBook() async {
    setState(() => _isProcessing = true);
    try {
      final success = widget.onCloseBook != null
          ? await widget.onCloseBook!()
          : true;
      if (success && mounted) {
        setState(() {
          _isClosed = true;
          _closedAtText = _todayText();
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUnlockBook() async {
    setState(() => _isProcessing = true);
    try {
      final success = widget.onUnlockBook != null
          ? await widget.onUnlockBook!()
          : true;
      if (success && mounted) {
        setState(() {
          _isClosed = false;
          _closedAtText = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _todayText() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // 5. Rời nhóm
  Future<void> _handleLeaveGroup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Kiểm tra sạch nợ
    if (widget.currentUserNetBalance != 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Không thể rời nhóm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
            ),
          ),
          content: Text(
            'Bạn vẫn còn công nợ chưa tất toán trong nhóm (${widget.currentUserNetBalance > 0 ? "+${widget.currentUserNetBalance} đ" : "${widget.currentUserNetBalance} đ"}).\n\nVui lòng hoàn tất thanh toán trước khi rời nhóm.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_isCaptain) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Bạn là Trưởng nhóm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Trưởng nhóm không thể tự ý rời nhóm. Vui lòng chuyển vai trò Trưởng nhóm cho thành viên khác trước khi rời.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rời khỏi nhóm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm này không? Toàn bộ lịch sử chi tiêu cũ vẫn sẽ được lưu lại.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Rời nhóm',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onLeaveGroup != null
            ? await widget.onLeaveGroup!()
            : true;
        if (success && mounted) {
          Navigator.of(context).pop(); // Đóng bottom sheet
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 6. Giải tán nhóm
  Future<void> _handleDisbandGroup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Giải tán toàn bộ nhóm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
          ),
        ),
        content: Text(
          'CẢNH BÁO: Hành động này sẽ giải tán và xóa nhóm hoàn toàn. Bạn chỉ có thể giải tán khi toàn bộ thành viên đã cân bằng sạch nợ 100%.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Xác nhận giải tán',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onDisbandGroup != null
            ? await widget.onDisbandGroup!()
            : true;
        if (success && mounted) {
          Navigator.of(context).pop(); // Đóng bottom sheet
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: isDark
            ? const Border(
                top: BorderSide(color: Color(0xFF334155)),
                left: BorderSide(color: Color(0xFF334155)),
                right: BorderSide(color: Color(0xFF334155)),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Tiêu đề căn giữa + Nút X
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Cài đặt nhóm',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Quản trị thông tin và vai trò thành viên trong nhóm.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Nội dung cuộn được (ẩn scrollbar)
          Flexible(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Thông tin nhóm
                    _buildSectionTitle('Thông tin nhóm'),
                    const SizedBox(height: 8),
                    _buildGroupInfoCard(),

                    const SizedBox(height: 18),

                    // Section 2: Quản trị thành viên
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Thành viên (${_members.length})'),
                        if (_isCaptain && _members.length > 1)
                          Tooltip(
                            message: 'Chuyển Trưởng nhóm',
                            child: InkWell(
                              onTap: _adminLocked ? null : _handleTransferCaptain,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    HugeIcons.strokeRoundedExchange01,
                                    size: 16,
                                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMembersListCard(),

                    const SizedBox(height: 18),

                    // Section 3: Trạng thái bill
                    _buildSectionTitle('Trạng thái bill'),
                    const SizedBox(height: 8),
                    _buildBillStatusCard(),

                    const SizedBox(height: 20),

                    // Section 4: Vùng nguy hiểm (Danger Zone)
                    _buildSectionTitle('Vùng nguy hiểm', isDanger: true),
                    const SizedBox(height: 8),
                    _buildDangerZoneCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDanger
            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monogram = _groupName.isNotEmpty
        ? _groupName
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'GP';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F766E).withValues(alpha: 0.25)
                  : const Color(0xFFF0FDFA),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF14B8A6).withValues(alpha: 0.4)
                    : const Color(0xFFCCFBF1),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              monogram,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _groupName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isCaptain)
                      Tooltip(
                        message: 'Đổi tên nhóm',
                        child: InkWell(
                          onTap: _adminLocked ? null : _handleRename,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                HugeIcons.strokeRoundedEdit02,
                                size: 16,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tiền tệ: ${widget.groupCurrency} • Tạo ngày ${widget.createdAtText}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersListCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _members.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        itemBuilder: (context, index) {
          final member = _members[index];
          final monogram = member.displayName.isNotEmpty
              ? member.displayName
                    .split(' ')
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase()
              : 'TV';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  child: Text(
                    monogram,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isCaptain) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF78350F).withValues(alpha: 0.35)
                                    : const Color(0xFFFEF3C7),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFFD97706).withValues(alpha: 0.4)
                                      : const Color(0xFFFDE68A),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedCrown,
                                    size: 10,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF92400E),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Trưởng nhóm',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        member.isCurrentUser
                            ? 'Bạn'
                            : (member.isCaptain
                                  ? 'Người tạo nhóm'
                                  : 'Thành viên'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCaptain && !member.isCaptain)
                  Tooltip(
                    message: 'Xóa thành viên',
                    child: InkWell(
                      onTap: _adminLocked
                          ? null
                          : () => _handleRemoveMember(member),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                              : const Color(0xFFFEF2F2),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : const Color(0xFFFECACA),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            HugeIcons.strokeRoundedUserRemove01,
                            size: 18,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Thẻ trạng thái nhận bill: Switch Toggle On/Off 2 chiều (chỉ Captain được thao tác).
  Widget _buildBillStatusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = _isClosed
        ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB))
        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDFA));

    final border = _isClosed
        ? (isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : const Color(0xFFFDE68A))
        : (isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFCCFBF1));

    final iconColor = _isClosed
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
        : (isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isClosed ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isClosed
                      ? (_closedAtText == null
                          ? 'Đang khóa nhận hóa đơn mới'
                          : 'Đang khóa nhận hóa đơn ($_closedAtText)')
                      : 'Khóa nhận hóa đơn mới',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !_isCaptain
                      ? 'Chỉ Trưởng nhóm mới có quyền bật/tắt nhận hóa đơn mới.'
                      : _isClosed
                          ? 'Tạm dừng nhận thêm bill mới. Gạt tắt để mở nhận bill trở lại.'
                          : 'Chặn thành viên tạo/quét thêm bill mới. Các bill hiện có vẫn sửa/chốt được.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_isCaptain) ...[
            const SizedBox(width: 8),
            Switch(
              value: _isClosed,
              onChanged: _isProcessing ? null : _handleToggleLock,
              activeThumbColor: const Color(0xFF14B8A6),
              activeTrackColor: isDark ? const Color(0xFF0F766E) : const Color(0xFFCCFBF1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.25)
            : const Color(0xFFFEF2F2),
        border: Border.all(
          color: isDark
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : const Color(0xFFFECACA),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rời khỏi nhóm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bạn chỉ có thể rời nhóm khi không còn bất kỳ khoản nợ nào.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Rời khỏi nhóm',
                child: InkWell(
                  onTap: _adminLocked ? null : _handleLeaveGroup,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : const Color(0xFFFECACA),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        HugeIcons.strokeRoundedLogout01,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isCaptain) ...[
            Divider(
              height: 20,
              color: isDark
                  ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                  : const Color(0xFFFECACA),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giải tán nhóm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xóa toàn bộ nhóm sau khi tất cả thành viên đã cân bằng sạch nợ.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Giải tán nhóm',
                  child: InkWell(
                    onTap: _isProcessing ? null : _handleDisbandGroup,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          HugeIcons.strokeRoundedDelete02,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
