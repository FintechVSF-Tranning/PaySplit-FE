import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settlementControllerProvider.notifier).setTab(widget.initialTab);
    });
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
    try {
      await ref
          .read(settlementControllerProvider.notifier)
          .remindDebt(groupId: debt.groupId, debtId: debt.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Đã gửi lời nhắc đến ${debt.debtorName}.');
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'Không thể gửi lời nhắc nợ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settlementControllerProvider);
    final controller = ref.read(settlementControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final payableCount = state.payableDebts
        .where((d) => d.status.name == 'awaiting')
        .length;
    final receivableCount =
        state.receivableDebts.where((d) => d.status.name == 'awaiting').length +
        state.pendingProofs.where((proof) => !proof.isSettled).length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          HugeIcons.strokeRoundedArrowLeft01,
                          size: 18,
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
                            color: textMain,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Tổng hợp công nợ đa nhóm & đối soát minh chứng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        showComingSoonSnackBar(context, 'Tìm kiếm hóa đơn'),
                    icon: const Icon(HugeIcons.strokeRoundedSearch01, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.bankSettings),
                    icon: const Icon(HugeIcons.strokeRoundedBank, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cài đặt STK nhận tiền VietQR',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Hero Summary Card
              SettlementHeroSummaryCard(
                overview: state.overview,
                onPayDebt: _openBatchPaySheet,
                onTapPendingProofAlert: () {
                  controller.setTab(SettlementTab.receivable);
                },
              ),
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
                        onTap: () => controller.setTab(SettlementTab.payable),
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
                        title: 'Hóa đơn (${state.bills.length})',
                        tab: SettlementTab.bills,
                        activeTab: state.currentTab,
                        isDark: isDark,
                        onTap: () => controller.setTab(SettlementTab.bills),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Lịch sử',
                        tab: SettlementTab.history,
                        activeTab: state.currentTab,
                        isDark: isDark,
                        onTap: () => controller.setTab(SettlementTab.history),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Tab Panels Content
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
                      const Expanded(
                        child: Text(
                          'Không tải hoặc cập nhật được dữ liệu. Vui lòng thử lại.',
                          key: Key('settlement-error-message'),
                          style: TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                      TextButton(
                        onPressed: state.isLoading ? null : controller.loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (state.isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                  ),
                ),
              ] else ...[
                if (state.currentTab == SettlementTab.payable) ...[
                  PayableDebtsTab(
                    debts: state.payableDebts,
                    onPaySingleDebt: _openSinglePayQr,
                  ),
                ] else if (state.currentTab == SettlementTab.receivable) ...[
                  ReceivableProofsTab(
                    pendingProofs: state.pendingProofs,
                    receivableDebts: state.receivableDebts,
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
                    bills: state.bills,
                    onTapBill: (id, title) {
                      showComingSoonSnackBar(
                        context,
                        'Chi tiết hóa đơn: $title',
                      );
                    },
                    onScanBill: () {
                      showComingSoonSnackBar(
                        context,
                        'Mở máy quét OCR hóa đơn',
                      );
                    },
                  ),
                ] else if (state.currentTab == SettlementTab.history) ...[
                  SettledHistoryTab(
                    history: state.settledHistory,
                    onTapHistoryItem: (item) {
                      _refreshAndOpenProof(item.proof);
                    },
                  ),
                ],
              ],
            ],
          ),
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
