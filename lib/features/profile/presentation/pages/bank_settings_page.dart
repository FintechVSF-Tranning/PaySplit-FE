import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class BankOption {
  final String code;
  final String shortName;
  final String fullName;
  final String bin;

  const BankOption({
    required this.code,
    required this.shortName,
    required this.fullName,
    required this.bin,
  });
}

class BankSettingsPage extends ConsumerStatefulWidget {
  const BankSettingsPage({super.key});

  @override
  ConsumerState<BankSettingsPage> createState() => _BankSettingsPageState();
}

class _BankSettingsPageState extends ConsumerState<BankSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  static const List<BankOption> _allBanks = [
    BankOption(code: 'MB', shortName: 'MBBank', fullName: 'Ngân hàng TMCP Quân Đội', bin: '970422'),
    BankOption(code: 'VCB', shortName: 'Vietcombank', fullName: 'Ngân hàng TMCP Ngoại Thương', bin: '970436'),
    BankOption(code: 'TCB', shortName: 'Techcombank', fullName: 'Ngân hàng TMCP Kỹ Thương', bin: '970407'),
    BankOption(code: 'VPB', shortName: 'VPBank', fullName: 'Ngân hàng TMCP Việt Nam Thịnh Vượng', bin: '970432'),
    BankOption(code: 'ACB', shortName: 'ACB', fullName: 'Ngân hàng TMCP Á Châu', bin: '970416'),
    BankOption(code: 'BIDV', shortName: 'BIDV', fullName: 'Ngân hàng TMCP Đầu Tư và Phát Triển', bin: '970418'),
    BankOption(code: 'CTG', shortName: 'VietinBank', fullName: 'Ngân hàng TMCP Công Thương', bin: '970415'),
    BankOption(code: 'TPB', shortName: 'TPBank', fullName: 'Ngân hàng TMCP Tiên Phong', bin: '970423'),
    BankOption(code: 'OCB', shortName: 'OCB', fullName: 'Ngân hàng TMCP Phương Đông', bin: '970448'),
    BankOption(code: 'STB', shortName: 'Sacombank', fullName: 'Ngân hàng TMCP Sài Gòn Thương Tín', bin: '970403'),
    BankOption(code: 'MSB', shortName: 'MSB', fullName: 'Ngân hàng TMCP Hàng Hải', bin: '970426'),
    BankOption(code: 'VBA', shortName: 'Agribank', fullName: 'Ngân hàng Nông nghiệp & Phát triển Nông thôn', bin: '970405'),
    BankOption(code: 'SHB', shortName: 'SHB', fullName: 'Ngân hàng TMCP Sài Gòn - Hà Nội', bin: '970443'),
    BankOption(code: 'HDB', shortName: 'HDBank', fullName: 'Ngân hàng TMCP Phát triển TP.HCM', bin: '970437'),
    BankOption(code: 'VIB', shortName: 'VIB', fullName: 'Ngân hàng TMCP Quốc Tế', bin: '970441'),
    BankOption(code: 'LPB', shortName: 'LPBank', fullName: 'Ngân hàng TMCP Lộc Phát Việt Nam', bin: '970449'),
    BankOption(code: 'SEAB', shortName: 'SeABank', fullName: 'Ngân hàng TMCP Đông Nam Á', bin: '970440'),
  ];

  String? _initialBankCode;
  String _initialAccount = '';
  String _initialHolder = '';

  BankOption? _selectedBank;
  late TextEditingController _accountController;
  late TextEditingController _holderController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;

    if (user?.bankCode != null && user!.bankCode!.isNotEmpty) {
      try {
        _selectedBank = _allBanks.firstWhere((b) => b.code == user.bankCode);
      } catch (_) {
        _selectedBank = null;
      }
    } else {
      _selectedBank = null;
    }

    _initialBankCode = _selectedBank?.code;
    _initialAccount = user?.bankAccountNumber ?? '';
    _initialHolder = user?.bankAccountHolder ?? '';

    _accountController = TextEditingController(text: _initialAccount);
    _holderController = TextEditingController(text: _initialHolder);

    _accountController.addListener(() => setState(() {}));
    _holderController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _accountController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isLoading) return;

    if (_selectedBank == null) {
      showErrorSnackBar(context, 'Vui lòng chọn ngân hàng thụ hưởng');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authControllerProvider).value;
        final holder = VietnameseUtils.toBankHolderFormat(_holderController.text);
        await ref.read(authControllerProvider.notifier).updateProfile(
              name: user?.name,
              phoneNumber: user?.phoneNumber,
              bankCode: _selectedBank!.code,
              bankAccountNumber: _accountController.text.trim(),
              bankAccountHolder: holder,
            );
        if (mounted) {
          showSuccessSnackBar(context, 'Đã lưu tài khoản ngân hàng VietQR thành công!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          final message = e is Failure ? e.message : 'Lưu thông tin ngân hàng thất bại. Vui lòng thử lại.';
          showErrorSnackBar(context, message);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showBankSearchModal() {
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
            final filtered = _allBanks.where((b) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              return b.shortName.toLowerCase().contains(q) ||
                  b.fullName.toLowerCase().contains(q) ||
                  b.code.toLowerCase().contains(q);
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
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên ngân hàng...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(HugeIcons.strokeRoundedSearch01, color: Color(0xFF94A3B8), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final bank = filtered[index];
                          final isSelected = bank.code == _selectedBank?.code;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0F766E).withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAF9)),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFF0F766E), width: 1.5)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  bank.code.characters.take(3).toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? const Color(0xFF0F766E)
                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              bank.shortName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0F766E)
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            subtitle: Text(
                              bank.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 22)
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

    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryTeal = const Color(0xFF0F766E);

    final displayBankName = _selectedBank?.shortName ?? 'CHƯA CHỌN NGÂN HÀNG';
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
                        colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2E)],
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                          onTap: _showBankSearchModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                if (_selectedBank != null) ...[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedBank!.shortName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textMain,
                                          ),
                                        ),
                                        Text(
                                          _selectedBank!.fullName,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.1),
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
                                            'Chọn ngân hàng thụ hưởng',
                                            style: GoogleFonts.plusJakartaSans(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.1),
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
                        const SizedBox(height: 16),

                        // Số tài khoản
                        _buildFieldLabel('Số tài khoản', textMuted),
                        TextFormField(
                          controller: _accountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            color: textMain,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _buildInputDecoration('Ví dụ: 0123456789', isDark),
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
                        _buildFieldLabel('Tên chủ tài khoản (In hoa không dấu)', textMuted),
                        TextFormField(
                          controller: _holderController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            color: primaryTeal,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _buildInputDecoration('Ví dụ: NGUYEN VAN A', isDark),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên chủ tài khoản' : null,
                          onChanged: (val) {
                            final uppercase = val.toUpperCase();
                            if (uppercase != val) {
                              _holderController.value = _holderController.value.copyWith(
                                text: uppercase,
                                selection: TextSelection.collapsed(offset: uppercase.length),
                              );
                            }
                          },
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
                  final hasChanged = _selectedBank?.code != _initialBankCode ||
                      _accountController.text.trim() != _initialAccount ||
                      _holderController.text.trim().toUpperCase() != _initialHolder.toUpperCase();
                  final canSave = _selectedBank != null &&
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
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
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
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8)),
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
