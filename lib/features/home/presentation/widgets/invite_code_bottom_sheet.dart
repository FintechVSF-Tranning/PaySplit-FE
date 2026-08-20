import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// DTO biểu diễn thông tin một mã mời hiển thị trong Bottom Sheet
class InviteCodeItem {
  final String id;
  final String code;
  final String statusText;
  final String inviteUrl;

  const InviteCodeItem({
    required this.id,
    required this.code,
    required this.statusText,
    required this.inviteUrl,
  });

  InviteCodeItem copyWith({
    String? id,
    String? code,
    String? statusText,
    String? inviteUrl,
  }) {
    return InviteCodeItem(
      id: id ?? this.id,
      code: code ?? this.code,
      statusText: statusText ?? this.statusText,
      inviteUrl: inviteUrl ?? this.inviteUrl,
    );
  }
}

/// Modal Bottom Sheet quản lý mã mời (Invite Code Bottom Sheet)
///
/// Tuân thủ Design System PaySplit (Tally x Hallmark):
/// - Header: Tiêu đề "Quản lý mã mời" căn giữa, nút icon 'X' góc phải để đóng
/// - Danh sách mã mời: Highlight mã mời Mono, phụ đề trạng thái, nút Sao chép & Thu hồi
/// - Nút tạo mới: Nút full-width 100% "Tạo mã mời mới" ở đáy sheet
/// - Hỗ trợ `isScrollControlled: true` và `StatefulBuilder` để cập nhật UI mượt mà.
class InviteCodeBottomSheet extends StatefulWidget {
  final List<InviteCodeItem> initialInvites;
  final Future<InviteCodeItem?> Function()? onCreateInvite;
  final Future<bool> Function(String inviteId)? onRevokeInvite;

  const InviteCodeBottomSheet({
    super.key,
    required this.initialInvites,
    this.onCreateInvite,
    this.onRevokeInvite,
  });

  /// Hàm tiện ích hiển thị Bottom Sheet theo chuẩn Flutter Material 3
  static Future<void> show({
    required BuildContext context,
    required List<InviteCodeItem> initialInvites,
    Future<InviteCodeItem?> Function()? onCreateInvite,
    Future<bool> Function(String inviteId)? onRevokeInvite,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteCodeBottomSheet(
        initialInvites: initialInvites,
        onCreateInvite: onCreateInvite,
        onRevokeInvite: onRevokeInvite,
      ),
    );
  }

  @override
  State<InviteCodeBottomSheet> createState() => _InviteCodeBottomSheetState();
}

class _InviteCodeBottomSheetState extends State<InviteCodeBottomSheet> {
  late List<InviteCodeItem> _invites;
  bool _isCreating = false;
  String? _revokingId;

  @override
  void initState() {
    super.initState();
    _invites = List.from(widget.initialInvites);
  }

  Future<void> _handleCopy(InviteCodeItem item) async {
    await Clipboard.setData(ClipboardData(text: item.inviteUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sao chép link mời: ${item.inviteUrl}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRevoke(InviteCodeItem item) async {
    setState(() => _revokingId = item.id);
    try {
      final success = widget.onRevokeInvite != null
          ? await widget.onRevokeInvite!(item.id)
          : true;

      if (success && mounted) {
        setState(() {
          _invites.removeWhere((i) => i.id == item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thu hồi mã mời ${item.code}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _revokingId = null);
      }
    }
  }

  Future<void> _handleCreate() async {
    setState(() => _isCreating = true);
    try {
      if (widget.onCreateInvite != null) {
        final newInvite = await widget.onCreateInvite!();
        if (newInvite != null && mounted) {
          setState(() {
            _invites.insert(0, newInvite);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo mã mời mới thành công'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giới hạn chiều cao tối đa 85% màn hình khi scroll
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

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
          // 1. Drag Handle
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

          // 2. Header: Tiêu đề căn giữa & nút X góc phải
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Quản lý mã mời',
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

          // 3. Phụ đề hướng dẫn
          const Text(
            'Chia sẻ mã mời hoặc link để thêm bạn bè vào nhóm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto Slab',
              fontSize: 12,
              color: Color(0xFF676E5F),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Danh sách mã đang hoạt động
          Flexible(
            child: _invites.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Chưa có mã mời nào còn hiệu lực.\nHãy tạo mã mới để mời bạn bè.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto Slab',
                        fontSize: 13,
                        color: Color(0xFF676E5F),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _invites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _invites[index];
                      return _buildInviteCard(item);
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // 5. Nút tạo mã mới: Chiều ngang 100% (Full-width)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _handleCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E), // Deep Teal
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 18),
              label: Text(
                _isCreating ? 'Đang tạo...' : 'Tạo mã mời mới',
                style: const TextStyle(
                  fontFamily: 'Roboto Slab',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(InviteCodeItem item) {
    final isRevoking = _revokingId == item.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDBE0CE), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Mã mời + Phụ đề trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA), // Teal subtle
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.code,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.statusText,
                  style: const TextStyle(
                    fontFamily: 'Roboto Slab',
                    fontSize: 11,
                    color: Color(0xFF676E5F),
                  ),
                ),
              ],
            ),
          ),

          // 2 Nút thao tác: Sao chép + Thu hồi
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Sao chép
              OutlinedButton.icon(
                onPressed: () => _handleCopy(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C2118),
                  side: const BorderSide(color: Color(0xFFDBE0CE)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Sao chép',
                  style: TextStyle(
                    fontFamily: 'Roboto Slab',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút Thu hồi (Cảnh báo đỏ)
              OutlinedButton.icon(
                onPressed: isRevoking ? null : () => _handleRevoke(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626), // Danger red
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: isRevoking ? const Color(0xFFFEF2F2) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isRevoking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFFDC2626),
                        ),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text(
                  'Thu hồi',
                  style: TextStyle(
                    fontFamily: 'Roboto Slab',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
