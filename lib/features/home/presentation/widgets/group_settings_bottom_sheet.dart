import 'package:flutter/material.dart';

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
/// Tuân thủ Design System PaySplit (Tally x Hallmark / Forui):
/// - Header: Tiêu đề "Cài đặt nhóm" căn giữa, nút 'X' góc phải để đóng
/// - 3 Section chính:
///   1. Thông tin nhóm: Monogram, Tên nhóm (có nút Đổi tên cho Captain), Tiền tệ VND, Ngày tạo
///   2. Quản trị thành viên: Nút Chuyển quyền Trưởng nhóm, Danh sách thành viên kèm nút Xóa
///   3. Vùng nguy hiểm (Danger Zone): Nút Rời nhóm (kiểm tra sạch nợ), Giải tán nhóm (chỉ Captain)
class GroupSettingsBottomSheet extends StatefulWidget {
  final String groupId;
  final String initialGroupName;
  final String groupCurrency;
  final String createdAtText;
  final bool isCaptain;
  final int currentUserNetBalance; // Dùng để kiểm tra sạch nợ khi rời nhóm (0đ)
  final List<GroupMemberSettingItem> members;

  final Future<bool> Function(String newName)? onRenameGroup;
  final Future<bool> Function(String targetMembershipId)? onTransferCaptain;
  final Future<bool> Function(String targetMembershipId)? onRemoveMember;
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
    this.onRenameGroup,
    this.onTransferCaptain,
    this.onRemoveMember,
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
    Future<bool> Function(String newName)? onRenameGroup,
    Future<bool> Function(String targetMembershipId)? onTransferCaptain,
    Future<bool> Function(String targetMembershipId)? onRemoveMember,
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
        onRenameGroup: onRenameGroup,
        onTransferCaptain: onTransferCaptain,
        onRemoveMember: onRemoveMember,
        onLeaveGroup: onLeaveGroup,
        onDisbandGroup: onDisbandGroup,
      ),
    );
  }

  @override
  State<GroupSettingsBottomSheet> createState() => _GroupSettingsBottomSheetState();
}

class _GroupSettingsBottomSheetState extends State<GroupSettingsBottomSheet> {
  late String _groupName;
  late List<GroupMemberSettingItem> _members;
  late bool _isCaptain;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _groupName = widget.initialGroupName;
    _members = List.from(widget.members);
    _isCaptain = widget.isCaptain;
  }

  // 1. Đổi tên nhóm
  Future<void> _handleRename() async {
    final controller = TextEditingController(text: _groupName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Đổi tên nhóm',
          style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Nhập tên nhóm mới',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF676E5F))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Lưu thay đổi'),
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
            SnackBar(content: Text('Đã đổi tên nhóm thành "$newName"'), behavior: SnackBarBehavior.floating),
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
        const SnackBar(content: Text('Nhóm chưa có thành viên khác để chuyển quyền'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    GroupMemberSettingItem? selectedMember = candidateMembers.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Chuyển quyền Trưởng nhóm',
            style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn thành viên nhận vai trò Trưởng nhóm (Captain 👑). Bạn sẽ trở thành thành viên thông thường.',
                style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 12, color: Color(0xFF676E5F)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GroupMemberSettingItem>(
                initialValue: selectedMember,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: candidateMembers.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.displayName, style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 14)),
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
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF676E5F))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xác nhận chuyển'),
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
            SnackBar(content: Text('Đã chuyển quyền Trưởng nhóm cho ${selectedMember!.displayName}'), behavior: SnackBarBehavior.floating),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 3. Xóa thành viên
  Future<void> _handleRemoveMember(GroupMemberSettingItem member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Xác nhận xóa thành viên',
          style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${member.displayName}" khỏi nhóm không?\n\nLưu ý: Thành viên này phải không còn bất kỳ khoản nợ nào trong nhóm.',
          style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 13, color: Color(0xFF1C2118)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF676E5F))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa thành viên'),
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
            SnackBar(content: Text('Đã xóa thành viên ${member.displayName} khỏi nhóm'), behavior: SnackBarBehavior.floating),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 4. Rời nhóm
  Future<void> _handleLeaveGroup() async {
    // Kiểm tra sạch nợ
    if (widget.currentUserNetBalance != 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Không thể rời nhóm',
            style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
          ),
          content: Text(
            'Bạn vẫn còn công nợ chưa tất toán trong nhóm (${widget.currentUserNetBalance > 0 ? "+${widget.currentUserNetBalance} đ" : "${widget.currentUserNetBalance} đ"}).\n\nVui lòng hoàn tất thanh toán trước khi rời nhóm.',
            style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Bạn là Trưởng nhóm',
            style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Trưởng nhóm không thể tự ý rời nhóm. Vui lòng chuyển vai trò Trưởng nhóm cho thành viên khác trước khi rời.',
            style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Rời khỏi nhóm',
          style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm này không? Toàn bộ lịch sử chi tiêu cũ vẫn sẽ được lưu lại.',
          style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF676E5F))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onLeaveGroup != null ? await widget.onLeaveGroup!() : true;
        if (success && mounted) {
          Navigator.of(context).pop(); // Đóng bottom sheet
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 5. Giải tán nhóm
  Future<void> _handleDisbandGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Giải tán toàn bộ nhóm',
          style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
        ),
        content: const Text(
          'CẢNH BÁO: Hành động này sẽ giải tán và xóa nhóm hoàn toàn. Bạn chỉ có thể giải tán khi toàn bộ thành viên đã cân bằng sạch nợ 100%.',
          style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF676E5F))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận giải tán'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final success = widget.onDisbandGroup != null ? await widget.onDisbandGroup!() : true;
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
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                color: const Color(0xFFBFC6AF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Tiêu đề căn giữa + Nút X
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Cài đặt nhóm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Newsreader',
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C2118),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF676E5F)),
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
          const Text(
            'Quản trị thông tin và vai trò thành viên trong nhóm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 12, color: Color(0xFF676E5F)),
          ),
          const SizedBox(height: 16),

          // Nội dung cuộn được
          // Nội dung cuộn được (ẩn scrollbar)
          Flexible(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                        if (_isCaptain)
                          OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _handleTransferCaptain,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Color(0xFFDBE0CE)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF1C2118)),
                            label: const Text(
                              'Chuyển Trưởng nhóm',
                              style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1C2118)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMembersListCard(),

                    const SizedBox(height: 20),

                    // Section 3: Vùng nguy hiểm (Danger Zone)
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
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Roboto Slab',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF676E5F),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    final monogram = _groupName.isNotEmpty
        ? _groupName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'GP';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDBE0CE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              border: Border.all(color: const Color(0xFFCCFBF1)),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              monogram,
              style: const TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F766E),
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
                        style: const TextStyle(
                          fontFamily: 'Newsreader',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C2118),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isCaptain)
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleRename,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFDBE0CE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF1C2118)),
                        label: const Text(
                          'Đổi tên',
                          style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFF1C2118)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tiền tệ: ${widget.groupCurrency} • Tạo ngày ${widget.createdAtText}',
                  style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFF676E5F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDBE0CE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _members.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFDBE0CE)),
        itemBuilder: (context, index) {
          final member = _members[index];
          final monogram = member.displayName.isNotEmpty
              ? member.displayName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
              : 'TV';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF5F6F1),
                  child: Text(
                    monogram,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1C2118)),
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
                              style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isCaptain) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '👑 Trưởng nhóm',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        member.isCurrentUser ? 'Bạn' : (member.isCaptain ? 'Người tạo nhóm' : 'Thành viên'),
                        style: const TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFF676E5F)),
                      ),
                    ],
                  ),
                ),
                if (_isCaptain && !member.isCaptain)
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleRemoveMember(member),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.person_remove_outlined, size: 12, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rời khỏi nhóm',
                      style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bạn chỉ có thể rời nhóm khi không còn bất kỳ khoản nợ nào.',
                      style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFF676E5F)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handleLeaveGroup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 13, color: Color(0xFFDC2626)),
                label: const Text('Rời nhóm', style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_isCaptain) ...[
            const Divider(height: 20, color: Color(0xFFFECACA)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giải tán nhóm',
                        style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Xóa toàn bộ nhóm sau khi tất cả thành viên đã cân bằng sạch nợ.',
                        style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 11, color: Color(0xFF676E5F)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleDisbandGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                  label: const Text('Giải tán', style: TextStyle(fontFamily: 'Roboto Slab', fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
