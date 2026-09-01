import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/camera_operation_queue.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/web_camera_cleanup.dart';
import '../../../../di/injection.dart';
import '../../data/qr_image_decoder.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/invite_code.dart';
import '../../domain/usecases/preview_invite_usecase.dart';
import '../widgets/join_by_link_bottom_sheet.dart';

/// Màn hình quét QR để vào nhóm.
///
/// Camera quét liên tục mã QR. Ảnh từ thư viện và link thủ công là hai đường
/// dự phòng khi thiết bị không có camera hoặc người dùng từ chối quyền.
class ScanQrJoinPage extends StatefulWidget {
  const ScanQrJoinPage({super.key, this.scannerController});

  final MobileScannerController? scannerController;

  @override
  State<ScanQrJoinPage> createState() => _ScanQrJoinPageState();
}

class _ScanQrJoinPageState extends State<ScanQrJoinPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _scanLineController;
  late final MobileScannerController _scannerController;
  final CameraOperationQueue _scannerOperations = CameraOperationQueue();
  bool _isDecoding = false;
  bool _isDisposing = false;
  bool _isClosing = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController =
        widget.scannerController ??
        MobileScannerController(
          autoStart: false,
          formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
        );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    unawaited(_startScanner());
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _scanLineController.dispose();
    unawaited(_scannerOperations.schedule(_disposeScanner));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final scannerState = _scannerController.value;
    if (!scannerState.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startScanner());
      case AppLifecycleState.inactive:
        if (!kIsWeb) unawaited(_stopScanner());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_stopScanner());
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _startScanner() async {
    if (!mounted || _isDisposing || _isClosing) return;
    await _scannerOperations.schedule(() async {
      if (_isDisposing || _isClosing || _scannerController.value.isRunning) {
        return;
      }
      try {
        await _scannerController.start();
      } on MobileScannerException catch (error) {
        if (error.errorCode != MobileScannerErrorCode.controllerInitializing) {
          debugPrint('Start QR scanner error: $error');
        }
      }
    });
  }

  Future<void> _stopScanner() async {
    await _scannerOperations.schedule(_stopScannerNow);
  }

  Future<void> _stopScannerNow() async {
    try {
      await _scannerController.stop();
    } on MobileScannerException catch (error) {
      debugPrint('Stop QR scanner error: $error');
    }
    await stopWebCameraTracks();
  }

  Future<void> _disposeScanner() async {
    await _stopScannerNow();
    await _scannerController.dispose();
  }

  Future<void> _closeScanner([GroupEntity? result]) async {
    if (_isClosing) return;
    _isClosing = true;
    await _stopScanner();
    if (!mounted) return;

    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _toggleTorch() async {
    unawaited(HapticFeedback.selectionClick());
    try {
      await _scannerController.toggleTorch();
    } on MobileScannerException catch (error) {
      debugPrint('Toggle QR scanner torch error: $error');
    }
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isDecoding) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        unawaited(_processDetectedCode(raw));
        return;
      }
    }
  }

  Future<void> _processDetectedCode(String raw) async {
    if (_isDecoding || !mounted) return;
    setState(() => _isDecoding = true);
    await _stopScanner();

    final accepted = await _onCodeDetected(raw);
    if (!mounted || accepted) return;

    setState(() => _isDecoding = false);
    await _startScanner();
  }

  /// Điểm vào duy nhất cho mọi nguồn mã: camera và ảnh từ thư viện.
  ///
  /// Nhận **chuỗi thô** trong mã QR (chính là `invite_url`), tách lấy mã mời rồi
  /// xác thực với backend qua `GET /groups/invites/{code}` trước khi trả về màn
  /// gọi — không tin tưởng nội dung quét được.
  Future<bool> _onCodeDetected(String raw) async {
    final code = extractInviteCode(raw);
    if (code.length != kInviteCodeLength) {
      showErrorSnackBar(
        context,
        'Mã QR này không phải lời mời vào nhóm PaySplit.',
      );
      return false;
    }

    final result = await getIt<PreviewInviteUseCase>().call(code);
    if (!mounted) return false;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      showErrorSnackBar(context, failure.message);
      return false;
    }

    final preview = result.getRight().toNullable()!;
    await HapticFeedback.mediumImpact();
    if (!mounted) return false;
    await _closeScanner(
      GroupEntity(
        // Chưa biết id thật của nhóm trước khi tham gia.
        id: 'preview:$code',
        name: preview.groupName,
        memberCount: preview.activeMemberCount,
        myBalance: 0,
        inviteCode: code,
        isCaptain: false,
        lastActivity: 'Trưởng nhóm: ${preview.captainDisplayName}',
      ),
    );
    return true;
  }

  /// Chọn một ảnh QR từ thư viện và giải mã hoàn toàn phía client.
  ///
  /// Đây là đường dự phòng khi camera không khả dụng hoặc người dùng đã có ảnh.
  Future<void> _pickQrImage() async {
    if (_isDecoding) return;
    setState(() => _isDecoding = true);
    await _stopScanner();

    var accepted = false;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final decoded = decodeQrFromImageBytes(bytes);
      if (!mounted) return;

      switch (decoded) {
        case QrDecodeFailure(:final message):
          showErrorSnackBar(context, message);
        case QrDecodeSuccess(:final text):
          accepted = await _onCodeDetected(text);
      }
    } finally {
      if (mounted && !accepted) {
        setState(() => _isDecoding = false);
        await _startScanner();
      }
    }
  }

  Future<void> _openLinkEntry() async {
    if (_isDecoding) return;
    setState(() => _isDecoding = true);
    await _stopScanner();
    if (!mounted) return;

    final group = await JoinByLinkBottomSheet.show(context);
    if (!mounted) return;
    if (group != null) {
      await _closeScanner(group);
      return;
    }

    setState(() => _isDecoding = false);
    await _startScanner();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<GroupEntity>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_closeScanner(result));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _handleBarcodeCapture,
                placeholderBuilder: (_) => const _ScannerLoadingView(),
                errorBuilder: (_, error) =>
                    _ScannerErrorView(error: error, onRetry: _startScanner),
              ),
            ),
            const Positioned.fill(child: _CameraScrim()),
            Positioned.fill(
              child: IgnorePointer(
                child: _ScannerOverlay(controller: _scanLineController),
              ),
            ),

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
                          onTap: _closeScanner,
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
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _scannerController,
                          builder: (context, scannerState, _) {
                            final isTorchOn =
                                scannerState.torchState == TorchState.on;
                            final hasTorch =
                                scannerState.torchState !=
                                TorchState.unavailable;
                            return _GlassIconButton(
                              icon: isTorchOn
                                  ? HugeIcons.strokeRoundedFlash
                                  : HugeIcons.strokeRoundedFlashOff,
                              tooltip: hasTorch
                                  ? 'Đèn flash'
                                  : 'Thiết bị không hỗ trợ đèn flash',
                              isActive: isTorchOn,
                              onTap: hasTorch ? _toggleTorch : null,
                            );
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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _GhostAction(
                            icon: HugeIcons.strokeRoundedImage02,
                            label: _isDecoding
                                ? 'Đang đọc mã...'
                                : 'Chọn ảnh QR',
                            onTap: _isDecoding ? null : _pickQrImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GhostAction(
                            icon: HugeIcons.strokeRoundedLink01,
                            label: 'Nhập link',
                            onTap: _isDecoding ? null : _openLinkEntry,
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
      ),
    );
  }
}

class _CameraScrim extends StatelessWidget {
  const _CameraScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF071A16).withValues(alpha: 0.72),
            Colors.transparent,
            const Color(0xFF0B1120).withValues(alpha: 0.88),
          ],
          stops: const <double>[0, 0.45, 1],
        ),
      ),
    );
  }
}

/// Khung ngắm bo góc và vạch quét nằm trên preview camera thật.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ViewfinderCornersPainter()),
            ),
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
    );
  }
}

class _ScannerLoadingView extends StatelessWidget {
  const _ScannerLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0B1120),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = isPermissionDenied
        ? 'Cần cấp quyền Camera để quét mã QR.'
        : 'Không thể khởi động Camera. Bạn có thể thử lại hoặc chọn ảnh QR.';

    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                HugeIcons.strokeRoundedCameraOff01,
                size: 48,
                color: Colors.white70,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
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
  final VoidCallback? onTap;
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
  const _GhostAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// `null` để vô hiệu hóa trong lúc đang xử lý.
  final VoidCallback? onTap;

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
