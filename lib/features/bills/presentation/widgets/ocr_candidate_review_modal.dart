import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';

class OcrCandidateReviewModal extends StatefulWidget {
  final bool isScanning;
  final String? scanStep;
  final BillDetailEntity? candidate;
  final String? errorMessage;
  final List<CapturedBillPhoto> photos;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const OcrCandidateReviewModal({
    super.key,
    required this.isScanning,
    this.scanStep,
    this.candidate,
    this.errorMessage,
    required this.photos,
    required this.onApply,
    required this.onDismiss,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isScanning,
    String? scanStep,
    BillDetailEntity? candidate,
    String? errorMessage,
    required List<CapturedBillPhoto> photos,
    required VoidCallback onApply,
    required VoidCallback onDismiss,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isScanning,
      enableDrag: !isScanning,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrCandidateReviewModal(
        isScanning: isScanning,
        scanStep: scanStep,
        candidate: candidate,
        errorMessage: errorMessage,
        photos: photos,
        onApply: onApply,
        onDismiss: onDismiss,
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<OcrCandidateReviewModal> createState() => _OcrCandidateReviewModalState();
}

class _OcrCandidateReviewModalState extends State<OcrCandidateReviewModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _rainbowController;
  late Animation<double> _glowAnimation;
  late PageController _pageController;
  int _activePhotoIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pageController = PageController();

    if (widget.photos.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted || widget.photos.length <= 1 || !_pageController.hasClients) return;
      final nextIndex = (_activePhotoIndex + 1) % widget.photos.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant OcrCandidateReviewModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.length != widget.photos.length) {
      if (widget.photos.length > 1) {
        _startAutoScroll();
      } else {
        _autoScrollTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pulseController.dispose();
    _scanController.dispose();
    _rainbowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 16
            : 24,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Body based on OCR State
              if (widget.isScanning)
                _buildScanningState(context, isDark, textMain, textMuted)
              else if (widget.errorMessage != null)
                _buildErrorState(context, isDark, textMain, textMuted)
              else if (widget.candidate != null)
                _buildSuccessCandidateState(context, isDark, textMain, textMuted, border)
              else
                _buildScanningState(context, isDark, textMain, textMuted),
            ],
          ),
        ),
      ),
    );
  }

  /// ✨ Trạng thái đang quét hiển thị ảnh bill với hiệu ứng phép thuật ma thuật đa sắc & laser beam
  Widget _buildScanningState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
  ) {
    final photos = widget.photos;

    return AnimatedBuilder(
      animation: Listenable.merge([_scanController, _rainbowController, _pulseController]),
      builder: (context, _) {
        final scanProgress = _scanController.value;
        final rainbowProgress = _rainbowController.value;
        final pulseAlpha = _glowAnimation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header with Animated Shifting Sparkles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => SweepGradient(
                    colors: const [
                      Color(0xFF10B981),
                      Color(0xFF06B6D4),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                      Color(0xFF10B981),
                    ],
                    transform: GradientRotation(rainbowProgress * math.pi * 2),
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang giải mã hóa đơn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Bill Photo Showcase with Magic Scanner
            SizedBox(
              height: 290,
              child: Center(
                child: photos.isEmpty
                    ? _buildPlaceholderScanner(isDark, scanProgress, rainbowProgress, pulseAlpha)
                    : _buildPhotoScanner(photos, isDark, scanProgress, rainbowProgress, pulseAlpha),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Skip & Manual Entry Button
            AppButton(
              label: 'Bỏ qua & Tự nhập tay',
              variant: AppButtonVariant.outline,
              icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 17),
              onPressed: widget.onDismiss,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoScanner(
    List<CapturedBillPhoto> photos,
    bool isDark,
    double scanProgress,
    double rainbowProgress,
    double pulseAlpha,
  ) {
    return Container(
      width: 220,
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Rotating Rainbow Magic Border
        gradient: SweepGradient(
          transform: GradientRotation(rainbowProgress * math.pi * 2),
          colors: const [
            Color(0xFF10B981), // Emerald
            Color(0xFF06B6D4), // Cyan
            Color(0xFF8B5CF6), // Purple
            Color(0xFFEC4899), // Pink
            Color(0xFFF59E0B), // Amber
            Color(0xFF10B981), // Emerald
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35 * pulseAlpha + 0.15),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.25 * pulseAlpha + 0.10),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Bill Photo
            if (photos.length == 1)
              _buildPhotoImage(photos.first)
            else
              PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _activePhotoIndex = i),
                itemBuilder: (context, i) => _buildPhotoImage(photos[i]),
              ),

            // Layer 2: Shimmering Iridescent Aurora Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.5 + 3.0 * rainbowProgress, -1.0),
                      end: Alignment(0.5 + 3.0 * rainbowProgress, 1.0),
                      colors: [
                        const Color(0xFF06B6D4).withValues(alpha: 0.08),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                        const Color(0xFFEC4899).withValues(alpha: 0.18),
                        const Color(0xFF10B981).withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 3: HUD Corner Brackets
            const IgnorePointer(child: _CornerBracketsOverlay()),

            // Layer 4: Laser Scanning Line with Glow Trail
            IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;
                  final beamY = (totalHeight - 4) * scanProgress;

                  return Stack(
                    children: [
                      // Glow trail
                      Positioned(
                        top: math.max(0, beamY - 45),
                        left: 0,
                        right: 0,
                        height: math.min(beamY, 45),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                const Color(0xFF06B6D4).withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Sharp luminous laser beam
                      Positioned(
                        top: beamY,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF06B6D4),
                                Colors.white,
                                Color(0xFFEC4899),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.95),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.85),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Layer 5: Multi-photo indicator chip (if > 1 photo)
            if (photos.length > 1)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_activePhotoIndex + 1}/${photos.length}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderScanner(
    bool isDark,
    double scanProgress,
    double rainbowProgress,
    double pulseAlpha,
  ) {
    return Container(
      width: 220,
      height: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const _CornerBracketsOverlay(),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(CapturedBillPhoto photo) {
    Widget imageWidget;
    if (photo.hasBytes) {
      imageWidget = Image.memory(
        photo.bytes!,
        fit: BoxFit.cover,
      );
    } else if (photo.file != null) {
      imageWidget = Image.file(
        File(photo.file!.path),
        fit: BoxFit.cover,
      );
    } else if (photo.hasUrl) {
      imageWidget = Image.network(
        photo.url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.receipt_long_rounded, color: Colors.white38, size: 48),
        ),
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.receipt_long_rounded, color: Colors.white38, size: 48),
      );
    }

    return RotatedBox(
      quarterTurns: photo.rotationQuarterTurns,
      child: SizedBox.expand(child: imageWidget),
    );
  }

  /// ✅ Trạng thái bóc tách thành công (Xem trước candidate và áp dụng)
  Widget _buildSuccessCandidateState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
    Color border,
  ) {
    final candidate = widget.candidate!;
    final items = candidate.items;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã nhận diện ${items.length} món ăn!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quán: ${candidate.merchantName?.isNotEmpty == true ? candidate.merchantName : "Hoá đơn chi tiêu"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TỔNG CỘNG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textMuted,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatVND(candidate.total.toDouble()),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scrollable List of Parsed Items
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Không tìm thấy dòng món nào trong ảnh',
                      style: GoogleFonts.plusJakartaSans(color: textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(color: border, height: 1),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final hasDiscount = item.discountAmount > 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: border),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'KM: -${CurrencyFormatter.formatVND(item.discountAmount.toDouble())}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatVND(item.finalPrice.toDouble()),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  CurrencyFormatter.formatVND(item.lineTotal.toDouble()),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    color: textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),

        // Summary chips for adjustments if any
        if (candidate.serviceCharge > 0 || candidate.vat > 0 || candidate.generalDiscount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (candidate.serviceCharge > 0)
                  _buildPillTag(
                    'Phí DV: +${CurrencyFormatter.formatVND(candidate.serviceCharge.toDouble())}',
                    const Color(0xFF0F766E),
                    const Color(0xFFF0FDFA),
                  ),
                if (candidate.vat > 0)
                  _buildPillTag(
                    'VAT: +${CurrencyFormatter.formatVND(candidate.vat.toDouble())}',
                    const Color(0xFF2563EB),
                    const Color(0xFFEFF6FF),
                  ),
                if (candidate.generalDiscount > 0)
                  _buildPillTag(
                    'Voucher: -${CurrencyFormatter.formatVND(candidate.generalDiscount.toDouble())}',
                    const Color(0xFF059669),
                    const Color(0xFFECFDF5),
                  ),
              ],
            ),
          ),

        // Action Buttons
        AppButton(
          label: 'Áp dụng vào hoá đơn (${items.length} món)',
          variant: AppButtonVariant.gradient,
          icon: const Icon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            size: 18,
            color: Colors.white,
          ),
          onPressed: widget.onApply,
        ),
        const SizedBox(height: 8),

        AppButton(
          label: 'Không áp dụng, tự nhập tay',
          variant: AppButtonVariant.outline,
          icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 17),
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }

  Widget _buildPillTag(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  /// ❌ Trạng thái lỗi bóc tách
  Widget _buildErrorState(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textMuted,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFEF2F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            HugeIcons.strokeRoundedAlertCircle,
            color: Color(0xFFDC2626),
            size: 36,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Không thể tự động nhận diện hoá đơn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          widget.errorMessage ??
              'Ảnh chụp hoá đơn có thể bị mờ, lóa hoặc kết nối mạng không ổn định.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        AppButton(
          label: 'Thử quét lại',
          icon: const Icon(HugeIcons.strokeRoundedReload, size: 18, color: Colors.white),
          onPressed: widget.onRetry,
        ),
        const SizedBox(height: 8),

        AppButton(
          label: 'Bỏ qua & Tự nhập tay',
          variant: AppButtonVariant.outline,
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }
}

class _CornerBracketsOverlay extends StatelessWidget {
  const _CornerBracketsOverlay();

  @override
  Widget build(BuildContext context) {
    const cornerColor = Color(0xFF06B6D4);
    const cornerSize = 18.0;
    const cornerThickness = 2.5;

    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

