import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/bank_holder_input_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/bank_entity.dart';
import '../providers/supported_banks_provider.dart';

class BankSettingsPage extends ConsumerStatefulWidget {
  const BankSettingsPage({super.key});

  @override
  ConsumerState<BankSettingsPage> createState() => _BankSettingsPageState();
}

class _BankSettingsPageState extends ConsumerState<BankSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String? _initialBankCode;
  String _initialAccount = '';
  String _initialHolder = '';

  BankEntity? _selectedBank;
  late TextEditingController _accountController;
  late TextEditingController _holderController;

  /// Node của ô tên chủ tài khoản, để phím Next của ô số tài khoản nhảy sang.
  final _holderFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull;

    _initialBankCode = _normalizeBankCode(user?.bankCode);
    _initialAccount = user?.bankAccountNumber ?? '';
    _initialHolder = user?.bankAccountHolder ?? '';

    _accountController = TextEditingController(text: _initialAccount);
    _holderController = TextEditingController(text: _initialHolder);


    _accountController.addListener(() => setState(() {}));
    _holderController.addListener(() => setState(() {}));
  }

  String? _normalizeBankCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    return normalized == 'CTG' ? 'ICB' : normalized;
  }

  BankEntity? _bankByCode(List<BankEntity> banks, String? code) {
    if (code == null) return null;
    for (final bank in banks) {
      if (bank.code == code) return bank;
    }
    return null;
  }

  BankEntity? _effectiveSelectedBank(List<BankEntity> banks) =>
      _selectedBank ?? _bankByCode(banks, _initialBankCode);

  @override
  void dispose() {
    _holderFocusNode.dispose();
    _accountController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isLoading) return;

    final banks = ref.read(supportedBanksProvider).valueOrNull ?? const [];
    final selectedBank = _effectiveSelectedBank(banks);

    if (selectedBank == null) {
      showErrorSnackBar(context, 'Vui lòng chọn ngân hàng thụ hưởng');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authControllerProvider).valueOrNull;
        final holder = VietnameseUtils.toBankHolderFormat(
          _holderController.text,
        );
        await ref
            .read(authControllerProvider.notifier)
            .updateProfile(
              name: user?.name,
              phoneNumber: user?.phoneNumber,
              bankCode: selectedBank.code,
              bankAccountNumber: _accountController.text.trim(),
              bankAccountHolder: holder,
            );
        if (mounted) {
          showSuccessSnackBar(
            context,
            'Đã lưu tài khoản ngân hàng VietQR thành công!',
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          final message = e is Failure
              ? e.message
              : 'Lưu thông tin ngân hàng thất bại. Vui lòng thử lại.';
          showErrorSnackBar(context, message);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showBankSearchModal(List<BankEntity> banks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = banks.where((b) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              final qAscii = VietnameseUtils.toBankHolderFormat(
                searchQuery,
              ).toLowerCase();
              return b.shortName.toLowerCase().contains(q) ||
                  b.name.toLowerCase().contains(q) ||
                  b.code.toLowerCase().contains(q) ||
                  VietnameseUtils.toBankHolderFormat(
                    b.shortName,
                  ).toLowerCase().contains(qAscii) ||
                  VietnameseUtils.toBankHolderFormat(
                    b.name,
                  ).toLowerCase().contains(qAscii);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Modal Header handle
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Modal Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chọn ngân hàng thụ hưởng',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                HugeIcons.strokeRoundedCancel01,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên ngân hàng...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              HugeIcons.strokeRoundedSearch01,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() => searchQuery = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Banks List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final bank = filtered[index];
                          final isSelected =
                              bank.code == _effectiveSelectedBank(banks)?.code;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 58,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: _BankLogo(
                                bank: bank,
                                fallbackColor: isSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            title: Text(
                              bank.shortName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0F766E)
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                              ),
                            ),
                            subtitle: Text(
                              bank.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 22,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selectedBank = bank);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banksAsync = ref.watch(supportedBanksProvider);
    final banks = banksAsync.valueOrNull ?? const <BankEntity>[];
    final selectedBank = _effectiveSelectedBank(banks);

    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primaryTeal = const Color(0xFF0F766E);

    final displayBankName = selectedBank?.shortName ?? 'CHƯA CHỌN NGÂN HÀNG';
    final displayAccount = _accountController.text.trim().isNotEmpty
        ? _accountController.text.trim()
        : '•••• •••• ••••';
    final displayHolder = _holderController.text.trim().isNotEmpty
        ? _holderController.text.trim().toUpperCase()
        : 'CHƯA NHẬP CHỦ TÀI KHOẢN';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: textMain),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tài khoản VietQR',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: border, height: 1),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live VietQR Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F766E),
                          Color(0xFF115E59),
                          Color(0xFF042F2E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayBankName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'VIETQR NAPAS 247',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'SỐ TÀI KHOẢN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayAccount,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayHolder,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5EEAD4),
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              HugeIcons.strokeRoundedQrCode,
                              color: Colors.white,
                              size: 26,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Nhóm Form nhập liệu
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.02,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THÔNG TIN TÀI KHOẢN NHẬN TIỀN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Ngân hàng có Search
                        _buildFieldLabel('Ngân hàng thụ hưởng', textMuted),
                        InkWell(
                          onTap: banksAsync.isLoading
                              ? null
                              : () {
                                  if (banks.isEmpty) {
                                    ref.invalidate(supportedBanksProvider);
                                    return;
                                  }
                                  _showBankSearchModal(banks);
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: banksAsync.when(
                              loading: () => Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Đang tải danh sách ngân hàng...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        color: textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              error: (error, stackTrace) => Row(
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedAlertCircle,
                                    size: 20,
                                    color: textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Không tải được danh sách. Chạm để thử lại',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              data: (_) => Row(
                                children: [
                                  if (selectedBank != null) ...[
                                    Container(
                                      width: 54,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: _BankLogo(
                                        bank: selectedBank,
                                        fallbackColor: textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedBank.shortName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textMain,
                                            ),
                                          ),
                                          Text(
                                            selectedBank.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Đổi ngân hàng',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.account_balance_outlined,
                                            size: 20,
                                            color: textMuted,
                                          ),
                                          Expanded(
                                            child: Text(
                                              banks.isEmpty
                                                  ? 'Chưa có ngân hàng được hỗ trợ'
                                                  : 'Chọn ngân hàng thụ hưởng',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: textMuted,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Chọn ngay',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Số tài khoản
                        _buildFieldLabel('Số tài khoản', textMuted),
                        TextFormField(
                          controller: _accountController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _holderFocusNode.requestFocus(),
                          // `keyboardType` chỉ là gợi ý cho bàn phím: bàn phím
                          // vật lý và một số IME vẫn gõ được chữ vào đây, và
                          // người dùng chỉ biết mình sai sau khi bấm Lưu. Trần
                          // 19 ký tự khớp với ràng buộc của backend.
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                          ],
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            color: textMain,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _buildInputDecoration(
                            'Ví dụ: 0123456789',
                            isDark,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập số tài khoản';
                            }
                            if (val.trim().length < 6) {
                              return 'Số tài khoản không hợp lệ (tối thiểu 6 số)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Tên chủ tài khoản
                        _buildFieldLabel(
                          'Tên chủ tài khoản (In hoa không dấu)',
                          textMuted,
                        ),
                        TextFormField(
                          controller: _holderController,
                          focusNode: _holderFocusNode,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onSave(),
                          // Chuẩn hóa bằng formatter, không phải bằng cách ghi
                          // đè controller trong onChanged — xem
                          // [BankHolderInputFormatter].
                          inputFormatters: [
                            const BankHolderInputFormatter(),
                            LengthLimitingTextInputFormatter(100),
                          ],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            color: primaryTeal,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _buildInputDecoration(
                            'Ví dụ: NGUYEN VAN A',
                            isDark,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Vui lòng nhập tên chủ tài khoản'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final hasChanged =
                      selectedBank?.code != _initialBankCode ||
                      _accountController.text.trim() != _initialAccount ||
                      _holderController.text.trim().toUpperCase() !=
                          _initialHolder.toUpperCase();
                  final canSave =
                      selectedBank != null &&
                      _accountController.text.trim().isNotEmpty &&
                      _holderController.text.trim().isNotEmpty &&
                      hasChanged &&
                      !_isLoading;

                  return InkWell(
                    onTap: canSave ? _onSave : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: canSave
                            ? const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: canSave
                            ? null
                            : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canSave
                            ? [
                                BoxShadow(
                                  color: primaryTeal.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Lưu tài khoản VietQR',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: canSave
                                      ? Colors.white
                                      : (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8)),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark) {
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        color: const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.bank, required this.fallbackColor});

  final BankEntity bank;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        bank.code.characters.take(3).toString(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fallbackColor,
        ),
      ),
    );

    if (bank.logoUrl.isEmpty) return fallback;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Image.network(
        bank.logoUrl,
        fit: BoxFit.contain,
        semanticLabel: 'Logo ngân hàng ${bank.shortName}',
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null ? child : fallback,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
