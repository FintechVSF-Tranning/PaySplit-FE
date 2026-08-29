import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../widgets/camera_scanner_overlay.dart';
import '../widgets/captured_photos_tray.dart';
import '../widgets/photo_detail_dialog.dart';

class BillCapturePage extends StatefulWidget {
  const BillCapturePage({
    super.key,
    this.groupId = 'g-1',
    this.groupName = 'Du lịch Đà Lạt',
  });

  final String groupId;
  final String groupName;

  @override
  State<BillCapturePage> createState() => _BillCapturePageState();
}

class _BillCapturePageState extends State<BillCapturePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxPhotos = 5;
  final ImagePicker _picker = ImagePicker();
  final List<CapturedBillPhoto> _photos = [];

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;

  bool _isFlashOn = false;
  bool _isProcessingImage = false;

  late AnimationController _shutterFlashController;
  late Animation<double> _shutterFlashAnimation;

  bool _isCameraLoading = true;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shutterFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _shutterFlashAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterFlashController, curve: Curves.easeOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraLoading = true;
      _cameraErrorMessage = null;
    });

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
            _isCameraLoading = false;
            _cameraErrorMessage = 'Không tìm thấy camera trên thiết bị.';
          });
        }
        return;
      }

      final camera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController?.dispose();
      _cameraController = controller;
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionDenied = false;
          _isCameraLoading = false;
          _cameraErrorMessage = null;
        });
      }
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code}, ${e.description}');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraLoading = false;
          if (e.code == 'CameraAccessDenied' ||
              e.code == 'CameraAccessDeniedWithoutPrompt' ||
              e.code == 'CameraAccessRestricted') {
            _isCameraPermissionDenied = true;
            _cameraErrorMessage =
                'Cần cấp quyền truy cập Camera để quét hóa đơn.';
          } else {
            _cameraErrorMessage =
                'Không thể mở Camera: ${e.description ?? e.code}';
          }
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      final errorStr = e.toString();
      final isNoCamera =
          errorStr.contains('Available cameras: 0') ||
          errorStr.contains('No available camera') ||
          errorStr.contains('CameraUnavailableException') ||
          errorStr.contains('CameraIdListIncorrectException');

      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraLoading = false;
          if (isNoCamera) {
            _cameraErrorMessage =
                'Máy ảo chưa bật Camera ảo (0 camera khả dụng).\nHãy chọn ảnh từ Thư viện hoặc cài đặt trên Điện thoại thật.';
          } else {
            _cameraErrorMessage = 'Không thể khởi động Camera ($e).';
          }
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _shutterFlashController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final nextFlash = !_isFlashOn;
    setState(() => _isFlashOn = nextFlash);
    unawaited(HapticFeedback.selectionClick());

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.setFlashMode(
          nextFlash ? FlashMode.torch : FlashMode.off,
        );
      } catch (e) {
        debugPrint('Set flash mode error: $e');
      }
    }
  }

  Future<void> _handleCaptureFromCamera() async {
    if (_photos.length >= _maxPhotos) {
      showErrorSnackBar(context, 'Tối đa $_maxPhotos ảnh cho mỗi hoá đơn.');
      return;
    }

    try {
      setState(() => _isProcessingImage = true);
      unawaited(HapticFeedback.heavyImpact());

      // Trigger shutter flash animation
      unawaited(
        _shutterFlashController.forward().then(
          (_) => _shutterFlashController.reverse(),
        ),
      );

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile picture = await _cameraController!.takePicture();
        final bytes = await picture.readAsBytes();
        _addPhoto(picture, bytes);
      } else {
        final XFile? captured = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 88,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (captured != null) {
          final bytes = await captured.readAsBytes();
          _addPhoto(captured, bytes);
        } else {
          _simulateCaptureIfDesired();
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      _simulateCaptureIfDesired();
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  static final Uint8List _dummyReceiptBytes = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  void _simulateCaptureIfDesired() {
    final dummyBytes = _dummyReceiptBytes;
    final dummyFile = XFile.fromData(
      dummyBytes,
      name: 'bill_receipt_${_photos.length + 1}.png',
    );
    _addPhoto(dummyFile, dummyBytes);
  }

  Future<void> _handlePickFromGallery() async {
    final remainingSlots = _maxPhotos - _photos.length;
    if (remainingSlots <= 0) {
      showErrorSnackBar(context, 'Đã đạt giới hạn tối đa $_maxPhotos ảnh.');
      return;
    }

    try {
      setState(() => _isProcessingImage = true);
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 88,
        limit: remainingSlots,
      );

      if (pickedFiles.isNotEmpty) {
        final filesToAdd = pickedFiles.take(remainingSlots).toList();
        for (final file in filesToAdd) {
          final bytes = await file.readAsBytes();
          _addPhoto(file, bytes);
        }
        if (mounted && pickedFiles.length > remainingSlots) {
          showErrorSnackBar(
            context,
            'Chỉ thêm được $remainingSlots ảnh (tối đa $_maxPhotos ảnh).',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'Không thể mở thư viện ảnh.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  bool _addPhoto(XFile file, Uint8List bytes) {
    if (_photos.length >= _maxPhotos) return false;

    final validationError = ImageValidator.validateImage(
      bytes: bytes,
      fileName: file.name,
    );
    if (validationError != null) {
      if (mounted) {
        showErrorSnackBar(context, validationError);
      }
      return false;
    }

    final newPhoto = CapturedBillPhoto(
      id: const Uuid().v4(),
      file: file,
      bytes: bytes,
      name: file.name,
      sizeBytes: bytes.lengthInBytes,
      capturedAt: DateTime.now(),
    );

    setState(() {
      _photos.add(newPhoto);
    });
    unawaited(HapticFeedback.selectionClick());
    return true;
  }

  void _removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      setState(() {
        _photos.removeAt(index);
      });
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _rotatePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      final current = _photos[index];
      setState(() {
        _photos[index] = current.copyWith(
          rotationQuarterTurns: (current.rotationQuarterTurns + 1) % 4,
        );
      });
    }
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _updatePhotoBytes(int index, Uint8List newBytes) {
    if (index >= 0 && index < _photos.length) {
      final current = _photos[index];
      setState(() {
        _photos[index] = current.copyWith(
          bytes: newBytes,
          sizeBytes: newBytes.lengthInBytes,
        );
      });
      showSuccessSnackBar(context, 'Đã cắt xén ảnh #${index + 1} thành công');
    }
  }

  void _openPhotoDetail(int index) {
    if (index < 0 || index >= _photos.length) return;
    PhotoDetailDialog.show(
      context,
      photo: _photos[index],
      currentIndex: index,
      totalCount: _photos.length,
      onDelete: () => _removePhoto(index),
      onRotate: () => _rotatePhoto(index),
      onCrop: (newBytes) => _updatePhotoBytes(index, newBytes),
    );
  }

  void _handleManualEntry() {
    final fallbackBill = BillDetailEntity(
      id: '',
      groupId: widget.groupId,
      groupName: widget.groupName,
      creditorMemberId: '',
      creditorName: '',
      status: 'draft',
      merchantName: 'Hoá đơn ${widget.groupName}',
      subtotal: 0,
      serviceCharge: 0,
      vat: 0,
      totalItemDiscount: 0,
      generalDiscount: 0,
      total: 0,
    );

    context.pushReplacement(
      AppRoutes.billDetail,
      extra: {'bill': fallbackBill},
    );
  }

  void _handleProceedToSplit() {
    if (_photos.isEmpty) return;

    final initialBill = BillDetailEntity(
      id: '',
      groupId: widget.groupId,
      groupName: widget.groupName,
      creditorMemberId: '',
      creditorName: '',
      status: 'draft',
      merchantName: 'Hoá đơn ${widget.groupName}',
      subtotal: 0,
      serviceCharge: 0,
      vat: 0,
      totalItemDiscount: 0,
      generalDiscount: 0,
      total: 0,
      photos: List.from(_photos),
    );

    context.pushReplacement(
      AppRoutes.billDetail,
      extra: {'bill': initialBill, 'autoStartOcr': true},
    );
  }

  void _showTipsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '💡 Mẹo chụp hoá đơn chuẩn AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildTipItem('1. Đặt hoá đơn trên mặt phẳng và đủ ánh sáng.'),
              _buildTipItem(
                '2. Căn góc chụp thẳng đứng, tránh bóng đổ hoặc gấp mép.',
              ),
              _buildTipItem(
                '3. Nhấn vào ảnh để xem to, cắt xén hoặc xoay 90°.',
              ),
              _buildTipItem(
                '4. Kéo thả các ảnh nhỏ để sắp xếp đúng thứ tự các trang hoá đơn.',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = _photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Dark Camera Backdrop
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar (Close [✕] & Dynamic Action Pill Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Close / Back button
                  _HeaderCircleButton(
                    icon: HugeIcons.strokeRoundedCancel01,
                    onTap: () => Navigator.of(context).maybePop(),
                    tooltip: 'Đóng',
                  ),

                  // Right: Dynamic Action Button
                  // - If 0 photos: "Nhập thủ công"
                  // - If >= 1 photos: "Chia tiền (N) ➔"
                  if (!hasPhotos)
                    _HeaderPillButton(
                      label: 'Nhập thủ công',
                      isHighlighted: false,
                      onTap: _handleManualEntry,
                    )
                  else
                    _HeaderPillButton(
                      label: 'Chia tiền (${_photos.length})',
                      trailingIcon: Icons.arrow_forward_rounded,
                      isHighlighted: true,
                      onTap: _handleProceedToSplit,
                    ),
                ],
              ),
            ),

            // 2. Camera Viewfinder Area (Takes remaining flex space cleanly)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Live Camera Preview or Placeholder
                      if (_isCameraInitialized &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _cameraController!.value.previewSize?.height ??
                                1,
                            height:
                                _cameraController!.value.previewSize?.width ??
                                1,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isCameraLoading)
                                  const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  Icon(
                                    _isCameraPermissionDenied
                                        ? HugeIcons.strokeRoundedCameraOff01
                                        : HugeIcons.strokeRoundedCamera01,
                                    size: 52,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  _isCameraLoading
                                      ? 'Đang khởi động Camera...'
                                      : (_cameraErrorMessage ??
                                            'Không thể kết nối Camera'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                if (!_isCameraLoading) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text('Thử lại'),
                                        onPressed: _initCamera,
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          HugeIcons.strokeRoundedImage01,
                                          size: 16,
                                        ),
                                        label: const Text('Mở Thư viện'),
                                        onPressed: _handlePickFromGallery,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // Interactive Scanner Overlay with Corner Guides & Animated Laser
                      CameraScannerOverlay(
                        isFlashOn: _isFlashOn,
                        onToggleFlash: _toggleFlash,
                      ),

                      // Shutter Flash Effect
                      AnimatedBuilder(
                        animation: _shutterFlashAnimation,
                        builder: (context, child) {
                          if (_shutterFlashAnimation.value == 0) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: Container(
                              color: Colors.white.withValues(
                                alpha: _shutterFlashAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Thumbnails Bar (Reorderable with Drag & Drop, fixed position below camera)
            if (hasPhotos)
              CapturedPhotosTray(
                photos: _photos,
                maxCount: _maxPhotos,
                onRemovePhoto: _removePhoto,
                onTapPhoto: _openPhotoDetail,
                onReorderPhotos: _reorderPhotos,
              ),

            // 4. Bottom Controls Area (Gallery, Shutter Button, Flash/Tips)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Gallery Button
                  _BottomActionButton(
                    icon: HugeIcons.strokeRoundedImage01,
                    label: 'Thư viện',
                    onTap: _handlePickFromGallery,
                  ),

                  // Center: Large Shutter Button
                  _ShutterButton(
                    onTap: _handleCaptureFromCamera,
                    isDisabled:
                        _photos.length >= _maxPhotos || _isProcessingImage,
                    photoCount: _photos.length,
                    maxCount: _maxPhotos,
                  ),

                  // Right: Flash Toggle / Tips Button
                  _BottomActionButton(
                    icon: _isFlashOn
                        ? HugeIcons.strokeRoundedFlash
                        : HugeIcons.strokeRoundedFlashOff,
                    label: _isFlashOn ? 'Flash Bật' : 'Flash Tắt',
                    isActive: _isFlashOn,
                    onTap: _toggleFlash,
                    onLongPress: _showTipsBottomSheet,
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

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 18)),
      ),
    );
  }
}

class _HeaderPillButton extends StatelessWidget {
  const _HeaderPillButton({
    required this.label,
    required this.isHighlighted,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF14B8A6)
                : Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF14B8A6)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF14B8A6) : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.onTap,
    required this.isDisabled,
    required this.photoCount,
    required this.maxCount,
  });

  final VoidCallback onTap;
  final bool isDisabled;
  final int photoCount;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFF14B8A6),
            width: 3.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white,
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              HugeIcons.strokeRoundedCamera01,
              size: 26,
              color: isDisabled
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
