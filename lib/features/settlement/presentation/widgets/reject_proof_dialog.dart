import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class RejectProofDialog extends StatefulWidget {
  const RejectProofDialog({required this.onRejectSubmitted, super.key});

  final Future<void> Function(String reason) onRejectSubmitted;

  @override
  State<RejectProofDialog> createState() => _RejectProofDialogState();
}

class _RejectProofDialogState extends State<RejectProofDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập lý do từ chối');
      return;
    }
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await widget.onRejectSubmitted(text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Không thể từ chối minh chứng. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Từ chối xác nhận tiền',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Khoản nợ sẽ được hoàn về trạng thái chờ chuyển. Vui lòng cho người nợ biết lý do (ví dụ: chưa nhận được tiền trên app banking, chuyển sai số tiền...).',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isSubmitting,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMain),
              decoration: InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: textMuted,
                ),
                errorText: _errorText,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceSubtle
                    : AppColors.surfaceSubtle,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderCol),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderCol),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF4444),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Đóng',
                    variant: AppButtonVariant.outline,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Gửi từ chối',
                    variant: AppButtonVariant.danger,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
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
