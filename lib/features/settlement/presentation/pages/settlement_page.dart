import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../../../core/widgets/header_wave_painter.dart';
import '../../../bills/presentation/widgets/group_picker_bottom_sheet.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../domain/entities/settlement_entities.dart';
import '../providers/settlement_controller.dart';
import '../widgets/all_bills_tab.dart';
import '../widgets/dynamic_vietqr_sheet.dart';
import '../widgets/payable_debts_tab.dart';
import '../widgets/proof_review_sheet.dart';
import '../widgets/receivable_proofs_tab.dart';
import '../widgets/reject_proof_dialog.dart';
import '../widgets/select_debt_batch_sheet.dart';
import '../widgets/settled_history_tab.dart';
import '../widgets/settlement_hero_summary_card.dart';

class SettlementPage extends ConsumerStatefulWidget {
  const SettlementPage({this.initialTab = SettlementTab.payable, super.key});

  final SettlementTab initialTab;

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends ConsumerState<SettlementPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settlementControllerProvider.notifier).setTab(widget.initialTab);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SettlementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(settlementControllerProvider.notifier)
            .setTab(widget.initialTab);
      });
    }
  }

  Future<void> _openBatchPaySheet() async {
    final selection = await showModalBottomSheet<BatchPaymentSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectDebtBatchSheet(),
    );

    if (!mounted || selection == null) return;
    await _generateAndOpenQr(
      groupId: selection.groupId,
      creditorId: selection.creditorId,
      creditorName: selection.creditorName,
      debtIds: selection.debtIds,
    );
  }

  Future<void> _openSinglePayQr(DebtItemEntity debt) {
    return _generateAndOpenQr(
      groupId: debt.groupId,
      creditorId: debt.creditorId,
      creditorName: debt.creditorName,
      debtIds: [debt.id],
    );
  }

  Future<void> _scanBill() async {
    final group = await GroupPickerBottomSheet.show(
      context,
      currentGroupId: '',
    );
    if (!mounted || group == null) return;
    await context.push(
      AppRoutes.scanBill,
      extra: {'groupId': group.id, 'groupName': group.name},
    );
    if (!mounted) return;
    await ref.read(settlementControllerProvider.notifier).loadData();
  }

  Future<void> _generateAndOpenQr({
    required String groupId,
    required String creditorId,
    required String creditorName,
    required List<String> debtIds,
  }) async {
    try {
      final controller = ref.read(settlementControllerProvider.notifier);
      final payment = await controller.generatePaymentQr(
        groupId: groupId,
        creditorId: creditorId,
        debtIds: debtIds,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DynamicVietQrSheet(
          payment: payment,
          creditorName: creditorName,
          lastErrorMessage: () =>
              ref.read(settlementControllerProvider).errorMessage,
          onSubmitProof: (image, note) async {
            await controller.submitProof(
              groupId: payment.groupId,
              paymentId: payment.id,
              image: image,
              note: note,
            );
            if (!mounted) return;
            showSuccessSnackBar(
              context,
              'Đã nộp biên lai cho $creditorName. Đang chờ xác nhận.',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // Controller đã map DioException -> Failure kèm message của BE (ví dụ chủ
      // nợ chưa cài tài khoản ngân hàng). Ưu tiên message đó thay vì câu chung.
      final failureMessage = ref
          .read(settlementControllerProvider)
          .errorMessage;
      showErrorSnackBar(
        context,
        failureMessage ??
            'Không thể tạo VietQR. Vui lòng kiểm tra tài khoản nhận và thử lại.',
      );
    }
  }

  Future<void> _openProofReviewSheet(ProofDetailEntity proof) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofReviewSheet(
        proof: proof,
        onConfirm: () async {
          await ref
              .read(settlementControllerProvider.notifier)
              .confirmPendingPayment(
                groupId: proof.groupId,
                paymentId: proof.paymentId,
              );
          if (!mounted) return;
          await HapticFeedback.mediumImpact();
          if (!mounted) return;
          showSuccessSnackBar(
            context,
            'Đã xác nhận thanh toán từ ${proof.debtorName}! Số dư đã được cập nhật.',
          );
        },
        onReject: () {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (_) => RejectProofDialog(
              onRejectSubmitted: (reason) async {
                await ref
                    .read(settlementControllerProvider.notifier)
                    .rejectPendingPayment(
                      groupId: proof.groupId,
                      paymentId: proof.paymentId,
                      reason: reason,
                    );
                if (!mounted) return;
                showErrorSnackBar(
                  context,
                  'Đã từ chối minh chứng. Khoản nợ đã được chuyển về trạng thái chờ thanh toán.',
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAndOpenProof(ProofDetailEntity proof) async {
    await ref.read(settlementControllerProvider.notifier).loadData();
    if (!mounted) return;
    final refreshed = ref.read(settlementControllerProvider);
    if (refreshed.errorMessage != null) {
      showErrorSnackBar(
        context,
        'Không thể tải lại ảnh biên lai. Vui lòng thử lại.',
      );
      return;
    }
    ProofDetailEntity? latest;
    for (final item in refreshed.pendingProofs) {
      if (item.paymentId == proof.paymentId) {
        latest = item;
        break;
      }
    }
    if (latest == null) {
      for (final item in refreshed.settledHistory) {
        if (item.proof.paymentId == proof.paymentId) {
          latest = item.proof;
          break;
        }
      }
    }
    if (latest == null) {
      showErrorSnackBar(
        context,
        'Không thể tải lại ảnh biên lai. Vui lòng thử lại.',
      );
      return;
    }
    await _openProofReviewSheet(latest);
  }

  Future<void> _rejectProof(ProofDetailEntity proof) {
    return showDialog<void>(
      context: context,
      builder: (_) => RejectProofDialog(
        onRejectSubmitted: (reason) async {
          await ref
              .read(settlementControllerProvider.notifier)
              .rejectPendingPayment(
                groupId: proof.groupId,
                paymentId: proof.paymentId,
                reason: reason,
              );
          if (mounted) {
            showErrorSnackBar(
              context,
              'Đã từ chối minh chứng và hoàn khoản nợ về trạng thái chờ.',
            );
          }
        },
      ),
    );
  }

  Future<void> _remindDebt(DebtItemEntity debt) async {
    final cooldown =
        ref.read(settlementControllerProvider).remindedCooldowns[debt.id] ??
        (debt.lastRemindedAt != null
            ? ((24 * 3600) -
                  DateTime.now().difference(debt.lastRemindedAt!).inSeconds)
            : 0);
    if (cooldown > 0) {
      return;
    }
    try {
      await ref
          .read(settlementControllerProvider.notifier)
          .remindDebt(groupId: debt.groupId, debtId: debt.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Đã gửi lời nhắc đến ${debt.debtorName}.');
      }
    } catch (_) {
      if (mounted) {
        final err = ref.read(settlementControllerProvider).errorMessage;
        if (err != null && err.isNotEmpty) {
          showErrorSnackBar(context, err);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(groupTabSearchResetProvider, (previous, next) {
      if (_isSearching || _searchQuery.isNotEmpty) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        setState(() {
          _isSearching = false;
          _searchQuery = '';
        });
      }
    });

    final state = ref.watch(settlementControllerProvider);
    final controller = ref.read(settlementControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    final filteredPayable = _searchQuery.isEmpty
        ? state.payableDebts
        : state.payableDebts
            .where((d) =>
                VietnameseUtils.matchesSearch(d.creditorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.debtorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.groupName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.billTitle, _searchQuery))
            .toList();

    final filteredReceivable = _searchQuery.isEmpty
        ? state.receivableDebts
        : state.receivableDebts
            .where((d) =>
                VietnameseUtils.matchesSearch(d.debtorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.creditorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.groupName, _searchQuery) ||
                VietnameseUtils.matchesSearch(d.billTitle, _searchQuery))
            .toList();

    final filteredProofs = _searchQuery.isEmpty
        ? state.pendingProofs
        : state.pendingProofs
            .where((p) =>
                VietnameseUtils.matchesSearch(p.debtorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(p.creditorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(p.groupName, _searchQuery) ||
                (p.note != null &&
                    VietnameseUtils.matchesSearch(p.note!, _searchQuery)))
            .toList();

    final filteredBills = _searchQuery.isEmpty
        ? state.bills
        : state.bills
            .where((b) =>
                VietnameseUtils.matchesSearch(b.title, _searchQuery) ||
                VietnameseUtils.matchesSearch(b.groupName, _searchQuery) ||
                VietnameseUtils.matchesSearch(b.payerDisplayName, _searchQuery))
            .toList();

    final filteredHistory = _searchQuery.isEmpty
        ? state.settledHistory
        : state.settledHistory
            .where((h) =>
                VietnameseUtils.matchesSearch(h.proof.debtorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(h.proof.creditorName, _searchQuery) ||
                VietnameseUtils.matchesSearch(h.proof.groupName, _searchQuery) ||
                (h.proof.note != null &&
                    VietnameseUtils.matchesSearch(h.proof.note!, _searchQuery)))
            .toList();

    final payableCount = filteredPayable
        .where((d) => d.status.name == 'awaiting')
        .length;
    final receivableCount =
        filteredReceivable.where((d) => d.status.name == 'awaiting').length +
        filteredProofs.where((proof) => !proof.isSettled).length;
    final billsCount = filteredBills.length;
    final historyCount = filteredHistory.length;

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(
                  double.infinity,
                  (_isSearching ? 80 : 210) + statusBarHeight,
                ),
                painter: HeaderWavePainter(isDark: isDark),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12 + statusBarHeight, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Bar
                  if (_isSearching)
                    Row(
                      children: [
                        // Nút đóng tìm kiếm
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                            });
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                HugeIcons.strokeRoundedArrowLeft01,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  HugeIcons.strokeRoundedSearch01,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    autofocus: true,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hintText:
                                          'Tìm theo tên hóa đơn, người trả...',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                    onChanged: (val) {
                                      setState(() => _searchQuery = val.trim());
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        HugeIcons.strokeRoundedCancel01,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.home);
                            }
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                HugeIcons.strokeRoundedArrowLeft01,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Công nợ & Hóa đơn',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Tổng hợp công nợ đa nhóm & đối soát minh chứng',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderCircleAction(
                          icon: HugeIcons.strokeRoundedSearch01,
                          tooltip: 'Tìm kiếm công nợ, hóa đơn',
                          isActive: _searchQuery.isNotEmpty,
                          onPressed: () {
                            setState(() => _isSearching = true);
                            _searchFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(width: 8),
                        _HeaderCircleAction(
                          icon: HugeIcons.strokeRoundedBank,
                          tooltip: 'Cài đặt STK nhận tiền VietQR',
                          onPressed: () => context.push(AppRoutes.bankSettings),
                        ),
                      ],
                    ),

                  if (!_isSearching) ...[
                    const SizedBox(height: 16),
                    // 2. Hero Summary Card
                    SettlementHeroSummaryCard(
                      overview: state.overview,
                      onPayDebt: _openBatchPaySheet,
                      onTapPendingProofAlert: () {
                        controller.setTab(SettlementTab.receivable);
                      },
                    ),
                  ],
                  const SizedBox(height: 18),

                  // 3. Segmented Pill Navigation Tabs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            title: 'Cần trả ($payableCount)',
                            tab: SettlementTab.payable,
                            activeTab: state.currentTab,
                            isDark: isDark,
                            onTap: () =>
                                controller.setTab(SettlementTab.payable),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: 'Cần thu ($receivableCount)',
                            tab: SettlementTab.receivable,
                            activeTab: state.currentTab,
                            isDark: isDark,
                            onTap: () =>
                                controller.setTab(SettlementTab.receivable),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: 'Hóa đơn ($billsCount)',
                            tab: SettlementTab.bills,
                            activeTab: state.currentTab,
                            isDark: isDark,
                            onTap: () => controller.setTab(SettlementTab.bills),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: 'Lịch sử ($historyCount)',
                            tab: SettlementTab.history,
                            activeTab: state.currentTab,
                            isDark: isDark,
                            onTap: () =>
                                controller.setTab(SettlementTab.history),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Tab Content View
                  if (state.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              key: const Key('settlement-error-message'),
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          ),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : controller.loadData,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (state.currentTab == SettlementTab.payable) ...[
                      if (filteredPayable.isEmpty && _searchQuery.isNotEmpty)
                        _EmptySettlementSearchState(
                          query: _searchQuery,
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      else
                        PayableDebtsTab(
                          debts: filteredPayable,
                          onPaySingleDebt: _openSinglePayQr,
                        ),
                    ] else if (state.currentTab ==
                        SettlementTab.receivable) ...[
                      if (filteredReceivable.isEmpty &&
                          filteredProofs.isEmpty &&
                          _searchQuery.isNotEmpty)
                        _EmptySettlementSearchState(
                          query: _searchQuery,
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      else
                        ReceivableProofsTab(
                          pendingProofs: filteredProofs,
                          receivableDebts: filteredReceivable,
                          remindedCooldowns: state.remindedCooldowns,
                          onOpenProofReview: _refreshAndOpenProof,
                          onConfirmProof: state.isMutating
                              ? null
                              : _refreshAndOpenProof,
                          onRejectProof: state.isMutating ? null : _rejectProof,
                          onRemindDebt: state.isMutating
                              ? null
                              : (debtId, _) {
                                  final debt = state.receivableDebts.firstWhere(
                                    (item) => item.id == debtId,
                                  );
                                  _remindDebt(debt);
                                },
                        ),
                    ] else if (state.currentTab == SettlementTab.bills) ...[
                      AllBillsTab(
                        bills: filteredBills,
                        searchQuery: _searchQuery,
                        onClearSearch: _searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              }
                            : null,
                        onTapBill: (bill) {
                          context.push(
                            AppRoutes.billDetail,
                            extra: {
                              'billId': bill.id,
                              'groupId': bill.groupId,
                              'groupName': bill.groupName,
                              'merchantName': bill.title,
                            },
                          );
                        },
                        onScanBill: _scanBill,
                      ),
                    ] else if (state.currentTab == SettlementTab.history) ...[
                      if (filteredHistory.isEmpty && _searchQuery.isNotEmpty)
                        _EmptySettlementSearchState(
                          query: _searchQuery,
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      else
                        SettledHistoryTab(
                          history: filteredHistory,
                          onTapHistoryItem: (item) {
                            _refreshAndOpenProof(item.proof);
                          },
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required SettlementTab tab,
    required SettlementTab activeTab,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = tab == activeTab;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Nút hành động tròn mờ trắng trên dải sóng Teal — đồng bộ style với
/// chuông thông báo ở Header Trang chủ.
class _HeaderCircleAction extends StatelessWidget {
  const _HeaderCircleAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            if (isActive)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng khi tìm kiếm không có kết quả phù hợp.
class _EmptySettlementSearchState extends StatelessWidget {
  const _EmptySettlementSearchState({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final iconBg = isDark
        ? const Color(0xFF0F766E).withValues(alpha: 0.25)
        : AppColors.primarySubtle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedSearch01,
                  size: 26,
                  color: isDark ? const Color(0xFF14B8A6) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Không tìm thấy kết quả phù hợp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Không có mục nào khớp với từ khóa "$query".\nHãy thử kiểm tra lại chính tả hoặc tìm theo từ khóa khác.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 16),
                label: Text(
                  'Xóa tìm kiếm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF14B8A6) : AppColors.primary,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF14B8A6) : AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

