import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/mock/group_mock_data.dart';
import '../../domain/entities/group_entity.dart';
import '../widgets/join_by_link_bottom_sheet.dart';

/// Màn hình quét QR để vào nhóm.
///
/// Khung ngắm, đèn flash và nút thư viện đã dựng đúng bố cục cuối; phần khung
/// hình camera hiện là placeholder mocup. Khi tích hợp thật, thay
/// [_ViewfinderPlaceholder] bằng `MobileScanner` và bắn kết quả qua
/// `_onCodeDetected`.
class ScanQrJoinPage extends StatefulWidget {
  const ScanQrJoinPage({super.key});

  @override
  State<ScanQrJoinPage> createState() => _ScanQrJoinPageState();
}

class _ScanQrJoinPageState extends State<ScanQrJoinPage> with SingleTickerProviderStateMixin {
  late final AnimationController _scanLineController;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  /// Điểm vào duy nhất khi có mã được nhận diện (mock hoặc camera thật).
  void _onCodeDetected(GroupEntity group) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          Positioned.fill(child: _ViewfinderPlaceholder(controller: _scanLineController)),

          SafeArea(
            child: Column(
              children: [
                // Header: back + tiêu đề + đèn flash
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        tooltip: 'Quay lại',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Quét QR vào nhóm',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _GlassIconButton(
                        icon: _isTorchOn
                            ? HugeIcons.strokeRoundedFlash
                            : HugeIcons.strokeRoundedFlashOff,
                        tooltip: 'Đèn flash',
                        isActive: _isTorchOn,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Text(
                  'Đưa mã QR của nhóm vào giữa khung',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),

                // Mô phỏng quét thành công để đi tiếp luồng khi chưa có camera.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: 'Mô phỏng quét thành công',
                    variant: AppButtonVariant.gradient,
                    icon: const Icon(HugeIcons.strokeRoundedQrCode, size: 18, color: Colors.white),
                    onPressed: () => _onCodeDetected(GroupMockData.myGroups.last),
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _GhostAction(
                          icon: HugeIcons.strokeRoundedImage02,
                          label: 'Chọn ảnh QR',
                          onTap: () => showComingSoonSnackBar(context, 'Quét QR từ thư viện'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GhostAction(
                          icon: HugeIcons.strokeRoundedLink01,
                          label: 'Nhập link',
                          onTap: () async {
                            final group = await JoinByLinkBottomSheet.show(context);
                            if (group != null && context.mounted) {
                              Navigator.of(context).pop(group);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nền camera giả lập + khung ngắm bo góc + vạch quét chạy dọc.
class _ViewfinderPlaceholder extends StatelessWidget {
  const _ViewfinderPlaceholder({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF132A24), Color(0xFF0B1120)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ViewfinderCornersPainter())),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return Positioned(
                    top: 12 + controller.value * 220,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF14B8A6).withValues(alpha: 0),
                            const Color(0xFF14B8A6),
                            const Color(0xFF14B8A6).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const arm = 34.0;
    const r = 22.0;

    // 4 góc khung ngắm, mỗi góc là 1 đoạn bo tròn chữ L.
    void corner(Offset origin, double dx, double dy) {
      final path = Path()
        ..moveTo(origin.dx + dx * arm, origin.dy)
        ..lineTo(origin.dx + dx * r, origin.dy)
        ..quadraticBezierTo(origin.dx, origin.dy, origin.dx, origin.dy + dy * r)
        ..lineTo(origin.dx, origin.dy + dy * arm);
      canvas.drawPath(path, paint);
    }

    corner(const Offset(2, 2), 1, 1);
    corner(Offset(size.width - 2, 2), -1, 1);
    corner(Offset(2, size.height - 2), 1, -1);
    corner(Offset(size.width - 2, size.height - 2), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF14B8A6).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
