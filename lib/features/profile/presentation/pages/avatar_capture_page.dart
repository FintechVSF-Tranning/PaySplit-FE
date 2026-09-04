import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/camera_operation_queue.dart';
import 'avatar_crop_page.dart';

/// Màn hình chụp ảnh đại diện bằng Camera thật.
///
/// Thiết kế giao diện camera toàn màn hình tự nhiên:
/// - Camera stream trực tiếp không bị che khuất.
/// - Ưu tiên camera trước (selfie), có nút lật camera trước/sau.
/// - Bật/tắt đèn Flash khi dùng camera sau.
/// - Rung phản hồi haptic & hiệu ứng chớp sáng shutter khi bấm chụp.
/// - Sau khi chụp xong: Chuyển sang màn hình căn chỉnh và cắt ảnh vào ô tròn ([AvatarCropPage]).
/// - Fallback sang chọn ảnh từ thư viện khi thiết bị không hỗ trợ camera.
class AvatarCapturePage extends StatefulWidget {
  const AvatarCapturePage({
    super.key,
    this.loadAvailableCameras = availableCameras,
    this.initialPreviewBytes,
    this.openCropPage,
  });

  /// Dependency seam để inject danh sách camera giả lập khi viết Widget Test.
  final Future<List<CameraDescription>> Function() loadAvailableCameras;

  /// Dữ liệu ảnh ban đầu (nếu muốn kích hoạt thẳng bước crop trong test).
  final Uint8List? initialPreviewBytes;

  /// Dependency seam để mock việc mở màn hình crop khi viết Widget Test.
  final Future<Uint8List?> Function(
    BuildContext context,
    Uint8List rawBytes,
    bool isFromCamera,
  )? openCropPage;

  @override
  State<AvatarCapturePage> createState() => _AvatarCapturePageState();
}

class _AvatarCapturePageState extends State<AvatarCapturePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  bool _isCameraLoading = true;
  String? _cameraErrorMessage;
  int _cameraSession = 0;
  final CameraOperationQueue _cameraOperations = CameraOperationQueue();
  bool _isPickingMedia = false;
  bool _wasCameraReleasedByLifecycle = false;

  bool _isFlashOn = false;
  bool _isProcessingImage = false;

  late AnimationController _shutterFlashController;
  late Animation<double> _shutterFlashAnimation;

  final ImagePicker _picker = ImagePicker();

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

    if (widget.initialPreviewBytes != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToCropPage(widget.initialPreviewBytes!, isFromCamera: false);
        }
      });
    }

    unawaited(_initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shutterFlashController.dispose();
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      unawaited(
        _cameraOperations.schedule(() async {
          try {
            await controller.dispose();
          } catch (_) {}
        }),
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPickingMedia) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasCameraReleasedByLifecycle = true;
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed &&
        _wasCameraReleasedByLifecycle) {
      _wasCameraReleasedByLifecycle = false;
      unawaited(_initCamera(preferredIndex: _selectedCameraIndex));
    }
  }

  Future<void> _initCamera({int? preferredIndex}) async {
    final int currentSession = ++_cameraSession;

    await _cameraOperations.schedule(() async {
      try {
        if (mounted) {
          setState(() {
            _isCameraLoading = true;
            _cameraErrorMessage = null;
            _isCameraPermissionDenied = false;
          });
        }

        final cameras = await widget.loadAvailableCameras();
        if (currentSession != _cameraSession || !mounted) return;

        if (cameras.isEmpty) {
          setState(() {
            _availableCameras = [];
            _isCameraInitialized = false;
            _isCameraLoading = false;
            _cameraErrorMessage = 'Không tìm thấy camera trên thiết bị này.';
          });
          return;
        }

        _availableCameras = cameras;

        // Ưu tiên chọn Camera trước (Selfie) cho chức năng avatar
        int targetIndex;
        if (preferredIndex != null && preferredIndex < cameras.length) {
          targetIndex = preferredIndex;
        } else {
          final frontIndex = cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
          );
          targetIndex = frontIndex != -1 ? frontIndex : 0;
        }
        _selectedCameraIndex = targetIndex;

        final oldController = _cameraController;
        _cameraController = null;
        if (oldController != null) {
          await oldController.dispose();
        }

        final newController = CameraController(
          cameras[targetIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await newController.initialize();
        if (currentSession != _cameraSession || !mounted) {
          await newController.dispose();
          return;
        }

        try {
          await newController
              .lockCaptureOrientation(DeviceOrientation.portraitUp);
        } catch (_) {}

        try {
          await newController.setFlashMode(FlashMode.off);
          _isFlashOn = false;
        } catch (_) {}

        _cameraController = newController;
        _isCameraInitialized = true;
        _isCameraLoading = false;
        if (mounted) setState(() {});
      } on CameraException catch (e) {
        if (currentSession != _cameraSession || !mounted) return;
        debugPrint('CameraException: ${e.code} - ${e.description}');
        setState(() {
          _isCameraInitialized = false;
          _isCameraLoading = false;
          if (e.code == 'CameraAccessDenied' ||
              e.code == 'CameraAccessDeniedWithoutPrompt' ||
              e.code == 'CameraAccessRestricted') {
            _isCameraPermissionDenied = true;
            _cameraErrorMessage =
                'Ứng dụng chưa được cấp quyền truy cập Camera. Vui lòng cấp quyền trong Cài đặt.';
          } else {
            _cameraErrorMessage =
                e.description ?? 'Không thể khởi động camera.';
          }
        });
      } catch (e) {
        if (currentSession != _cameraSession || !mounted) return;
        debugPrint('Error init camera: $e');
        setState(() {
          _isCameraInitialized = false;
          _isCameraLoading = false;
          _cameraErrorMessage = 'Đã có lỗi xảy ra khi mở camera.';
        });
      }
    });
  }

  Future<void> _releaseCamera() async {
    await _cameraOperations.schedule(() async {
      final controller = _cameraController;
      _cameraController = null;
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1 || _isProcessingImage) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initCamera(preferredIndex: nextIndex);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final isBackCamera =
        _availableCameras.isNotEmpty &&
        _selectedCameraIndex < _availableCameras.length &&
        _availableCameras[_selectedCameraIndex].lensDirection ==
            CameraLensDirection.back;
    if (!isBackCamera) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggle flash: $e');
    }
  }

  Future<void> _navigateToCropPage(
    Uint8List rawBytes, {
    required bool isFromCamera,
  }) async {
    Uint8List? croppedBytes;
    if (widget.openCropPage != null) {
      croppedBytes =
          await widget.openCropPage!(context, rawBytes, isFromCamera);
    } else {
      croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => AvatarCropPage(
            imageBytes: rawBytes,
            isFromCamera: isFromCamera,
          ),
        ),
      );
    }

    if (croppedBytes != null && mounted) {
      Navigator.of(context).pop(croppedBytes);
    }
  }

  Future<void> _takePicture() async {
    if (_isProcessingImage ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() => _isProcessingImage = true);
      unawaited(HapticFeedback.heavyImpact());

      // Hiệu ứng chớp màn hình trắng khi chụp
      unawaited(
        _shutterFlashController.forward().then(
          (_) => _shutterFlashController.reverse(),
        ),
      );

      final XFile picture = await _cameraController!.takePicture();
      final rawBytes = await picture.readAsBytes();

      if (mounted) {
        setState(() => _isProcessingImage = false);
        await _navigateToCropPage(rawBytes, isFromCamera: true);
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chụp ảnh. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    _isPickingMedia = true;
    await _releaseCamera();
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );
      if (picked != null) {
        final rawBytes = await picked.readAsBytes();
        if (mounted) {
          await _navigateToCropPage(rawBytes, isFromCamera: false);
        }
      }
    } catch (e) {
      debugPrint('Pick gallery error: $e');
    } finally {
      _isPickingMedia = false;
      if (mounted && _cameraController == null) {
        unawaited(_initCamera(preferredIndex: _selectedCameraIndex));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Toàn màn hình Camera Preview hoặc Loading/Fallback
          if (_isCameraInitialized && _cameraController != null)
            _buildLiveCameraView()
          else
            _buildFallbackOrLoadingView(),

          // 2. Hiệu ứng chớp sáng khi bấm chụp
          AnimatedBuilder(
            animation: _shutterFlashAnimation,
            builder: (context, _) {
              if (_shutterFlashAnimation.value <= 0.01) {
                return const SizedBox.shrink();
              }
              return Container(
                color: Colors.white.withValues(
                  alpha: _shutterFlashAnimation.value,
                ),
              );
            },
          ),

          // 3. Thanh công cụ trên cùng (Top Bar)
          _buildTopBar(),

          // 4. Thanh điều khiển chụp ảnh ở đáy (Bottom Bar)
          if (_isCameraInitialized) _buildCameraBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLiveCameraView() {
    return Center(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút Back
              _IconButtonBlurred(
                key: const Key('avatar-capture-back-button'),
                icon: HugeIcons.strokeRoundedArrowLeft01,
                onTap: () => Navigator.of(context).pop(),
              ),

              // Tiêu đề
              Text(
                'Chụp ảnh đại diện',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),

              // Spacer giữ cân bằng tiêu đề
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraBottomBar() {
    final isBackCamera =
        _availableCameras.isNotEmpty &&
        _selectedCameraIndex < _availableCameras.length &&
        _availableCameras[_selectedCameraIndex].lensDirection ==
            CameraLensDirection.back;
    final canFlash = isBackCamera;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Nút đèn flash (thay thế nút chọn ảnh từ thư viện)
              if (canFlash)
                InkWell(
                  key: const Key('avatar-capture-flash-button'),
                  onTap: _isProcessingImage ? null : _toggleFlash,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isFlashOn
                          ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFlashOn
                            ? const Color(0xFFFBBF24)
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      _isFlashOn
                          ? HugeIcons.strokeRoundedFlash
                          : HugeIcons.strokeRoundedFlashOff,
                      color:
                          _isFlashOn ? const Color(0xFFFBBF24) : Colors.white,
                      size: 22,
                    ),
                  ),
                )
              else
                const SizedBox(width: 52),

              // Nút chụp ảnh chính (Shutter Button)
              GestureDetector(
                key: const Key('avatar-capture-shutter-button'),
                onTap: _isProcessingImage ? null : _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _isProcessingImage
                        ? const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                  ),
                ),
              ),

              // Nút chuyển camera (Flip camera)
              if (_availableCameras.length > 1)
                InkWell(
                  key: const Key('avatar-capture-bottom-flip-button'),
                  onTap: _isProcessingImage ? null : _switchCamera,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              else
                const SizedBox(width: 52),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackOrLoadingView() {
    if (_isCameraLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF14B8A6),
            ),
            SizedBox(height: 16),
            Text(
              'Đang khởi động Camera...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(
                HugeIcons.strokeRoundedCameraOff01,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isCameraPermissionDenied
                  ? 'Quyền truy cập Camera bị từ chối'
                  : 'Không thể mở Camera',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _cameraErrorMessage ??
                  'Vui lòng kiểm tra quyền truy cập camera trong cài đặt thiết bị hoặc chọn ảnh từ thư viện.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('avatar-capture-fallback-gallery-button'),
                  onPressed: _pickFromGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    HugeIcons.strokeRoundedImage01,
                    size: 17,
                  ),
                  label: Text(
                    'Chọn từ thư viện',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  key: const Key('avatar-capture-retry-button'),
                  onPressed: () =>
                      _initCamera(preferredIndex: _selectedCameraIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Thử lại',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonBlurred extends StatelessWidget {
  const _IconButtonBlurred({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final dynamic icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: icon is IconData
              ? Icon(icon as IconData, color: Colors.white, size: 21)
              : Icon(icon as IconData, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
