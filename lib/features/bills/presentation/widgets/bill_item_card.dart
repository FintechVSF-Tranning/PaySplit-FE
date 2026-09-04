import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';
import 'avatar_assignment_bar.dart';

class BillItemCard extends StatelessWidget {
  final BillItemEntity item;
  final List<BillMemberEntity> members;
  final int itemIndex;
  final bool isEvenSplit;
  /// Được sửa nội dung món (giá, số lượng, xóa món) — chỉ Trưởng nhóm.
  final bool isEditable;

  /// Được gán người ăn cho món. Rộng hơn [isEditable]: Chủ chi cũng gán được,
  /// vì đó là việc chia phần chứ không phải sửa số tiền.
  final bool canAssign;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String memberId) onToggleMember;
  final VoidCallback onAssignAll;

  const BillItemCard({
    super.key,
    required this.item,
    required this.members,
    required this.itemIndex,
    this.isEvenSplit = false,
    this.isEditable = true,
    this.canAssign = true,
    required this.onTap,
    required this.onDelete,
    required this.onToggleMember,
    required this.onAssignAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final hasDiscount = item.discountAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Index + Item Name + Quantity + Price + Delete Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name & Quantity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${itemIndex + 1}. ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stacked Price
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.formatVND(item.finalPrice.toDouble()),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          if (hasDiscount)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatVND(item.lineTotal.toDouble()),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (isEditable) ...[
                      const SizedBox(width: 4),
                      // Delete Button
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(HugeIcons.strokeRoundedDelete02, size: 17),
                        color: const Color(0xFFDC2626),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ],
                ),

                if (!isEvenSplit) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Avatar Assignment Bar
                  AvatarAssignmentBar(
                    item: item,
                    members: members,
                    isEditable: canAssign,
                    onToggleMember: onToggleMember,
                    onAssignAll: onAssignAll,
                    onOpenDetail: onTap,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
