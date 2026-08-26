import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/settlement_entities.dart';

typedef ProofPicker = Future<ProofUploadEntity?> Function();

class DynamicVietQrSheet extends StatefulWidget {
  const DynamicVietQrSheet({
    required this.payment,
    required this.creditorName,
    required this.onSubmitProof,
    this.pickProof,
    super.key,
  });

  final PaymentQrEntity payment;
  final String creditorName;
  final Future<void> Function(ProofUploadEntity image, String? note)
  onSubmitProof;
  final ProofPicker? pickProof;

  @override
  State<DynamicVietQrSheet> createState() => _DynamicVietQrSheetState();
}

class _DynamicVietQrSheetState extends State<DynamicVietQrSheet> {
  static const _maxProofBytes = 10 * 1024 * 1024;

  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndSubmitProof() async {
    if (_isSubmitting) return;
    setState(() => _errorMessage = null);

    try {
      final image = await (widget.pickProof ?? _pickProofFromGallery)();
      if (image == null || !mounted) return;

      final bytes = image.bytes;
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > _maxProofBytes) {
        setState(() {
          _errorMessage =
              'Ảnh biên lai phải có dung lượng từ 1 byte đến 10 MB.';
        });
        return;
      }

      if (!_isSupportedImageName(image.name)) {
        setState(() {
          _errorMessage = 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc HEIC.';
        });
        return;
      }

      setState(() => _isSubmitting = true);
      final note = _noteController.text.trim();
      await widget.onSubmitProof(image, note.isEmpty ? null : note);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải biên lai. Vui lòng kiểm tra và thử lại.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<ProofUploadEntity?> _pickProofFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return ProofUploadEntity(name: _normalizedImageName(file), bytes: bytes);
  }

  String _normalizedImageName(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return file.name;
    if (name.endsWith('.png')) return file.name;
    if (name.endsWith('.heic') || name.endsWith('.heif')) return file.name;
    return switch (file.mimeType) {
      'image/jpeg' => '${file.name}.jpg',
      'image/png' => '${file.name}.png',
      'image/heic' || 'image/heif' => '${file.name}.heic',
      _ => file.name,
    };
  }

  bool _isSupportedImageName(String fileName) {
    final name = fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.heic') ||
        name.endsWith('.heif');
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceSubtle
        : AppColors.surfaceSubtle;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderStrong
                      : AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thanh toán qua VietQR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                  color: textMuted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0F766E),
                        width: 2,
                      ),
                    ),
                    child: Image.network(
                      payment.qrImageUrl,
                      key: const Key('vietqr-image'),
                      fit: BoxFit.contain,
                      semanticLabel: 'Mã VietQR thanh toán',
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text(
                              'Không tải được mã VietQR',
                              textAlign: TextAlign.center,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quét mã bằng ứng dụng Ngân hàng bất kỳ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.vnd(payment.amount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    'Người nhận:',
                    widget.creditorName,
                    textMain,
                    textMuted,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Ngân hàng:',
                    payment.bankName,
                    textMain,
                    textMuted,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Số tài khoản:',
                    payment.accountNumber,
                    textMain,
                    textMuted,
                    onCopy: () =>
                        _copyToClipboard(payment.accountNumber, 'số tài khoản'),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Chủ tài khoản:',
                    payment.accountHolder,
                    textMain,
                    textMuted,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Nội dung chuyển:',
                    payment.referenceCode,
                    const Color(0xFF0F766E),
                    textMuted,
                    onCopy: () => _copyToClipboard(
                      payment.referenceCode,
                      'nội dung chuyển',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    maxLength: 500,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      hintText: 'Lời nhắn gửi chủ nợ, tối đa 500 ký tự',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                key: const Key('proof-upload-error'),
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Tải ảnh biên lai đã chuyển',
              icon: const Icon(
                HugeIcons.strokeRoundedCamera01,
                size: 18,
                color: Colors.white,
              ),
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _pickAndSubmitProof,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Đóng',
              variant: AppButtonVariant.outline,
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color textMain,
    Color textMuted, {
    Future<void> Function()? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textMuted, fontSize: 12.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textMain,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 6),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 15),
            tooltip: 'Sao chép',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}
