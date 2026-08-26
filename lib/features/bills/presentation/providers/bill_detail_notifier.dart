import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/injection.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../../domain/repositories/bill_repository.dart';

class BillDetailState {
  final BillDetailEntity bill;
  final List<BillShareBreakdownEntity> breakdown;
  final bool isLoading;
  final bool isSaving;
  final bool isFinalizing;
  final bool isCalculatingBreakdown;
  final bool isOcrScanning;
  final String? ocrScanStep;
  final BillDetailEntity? ocrCandidate;
  final String? ocrErrorMessage;
  final String? errorMessage;
  final String? successMessage;
  final String? currentUserId;
  final Set<String>? evenSplitMemberIds;
  final bool isDirty;
  final bool isVoiding;

  const BillDetailState({
    required this.bill,
    this.breakdown = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isFinalizing = false,
    this.isCalculatingBreakdown = false,
    this.isOcrScanning = false,
    this.ocrScanStep,
    this.ocrCandidate,
    this.ocrErrorMessage,
    this.errorMessage,
    this.successMessage,
    this.currentUserId,
    this.evenSplitMemberIds,
    this.isDirty = false,
    this.isVoiding = false,
  });

  BillDetailState copyWith({
    BillDetailEntity? bill,
    List<BillShareBreakdownEntity>? breakdown,
    bool? isLoading,
    bool? isSaving,
    bool? isFinalizing,
    bool? isCalculatingBreakdown,
    bool? isOcrScanning,
    String? ocrScanStep,
    BillDetailEntity? ocrCandidate,
    bool clearOcrCandidate = false,
    bool clearOcrScanStep = false,
    String? ocrErrorMessage,
    String? errorMessage,
    String? successMessage,
    String? currentUserId,
    Set<String>? evenSplitMemberIds,
    bool? isDirty,
    bool? isVoiding,
  }) {
    return BillDetailState(
      bill: bill ?? this.bill,
      breakdown: breakdown ?? this.breakdown,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      isCalculatingBreakdown: isCalculatingBreakdown ?? this.isCalculatingBreakdown,
      isOcrScanning: isOcrScanning ?? this.isOcrScanning,
      ocrScanStep: clearOcrScanStep ? null : (ocrScanStep ?? this.ocrScanStep),
      ocrCandidate: clearOcrCandidate ? null : (ocrCandidate ?? this.ocrCandidate),
      ocrErrorMessage: ocrErrorMessage,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentUserId: currentUserId ?? this.currentUserId,
      evenSplitMemberIds: evenSplitMemberIds ?? this.evenSplitMemberIds,
      isDirty: isDirty ?? this.isDirty,
      isVoiding: isVoiding ?? this.isVoiding,
    );
  }

  /// Danh sách ID thành viên đang tham gia chia đều (mặc định là tất cả thành viên)
  Set<String> get activeEvenSplitMemberIds {
    if (evenSplitMemberIds != null && evenSplitMemberIds!.isNotEmpty) {
      return evenSplitMemberIds!;
    }
    return bill.members.map((m) => m.memberId).toSet();
  }

  /// Số tiền tạm tính chia đều trên mỗi người
  int get evenPerPersonAmount {
    final count = activeEvenSplitMemberIds.length;
    if (count == 0) return computedTotal;
    return (computedTotal / count).round();
  }

  /// Số lượng món chưa được gán cho ai trong nhóm
  int get unassignedCount => bill.items.where((i) => i.assignments.isEmpty).length;

  /// Kiểm tra xem user hiện tại có phải là Chủ chi của hoá đơn hay không
  bool get isCurrentUserCreditor {
    if (myShare != null) {
      return myShare!.isCreditor;
    }
    final myMember = bill.members.cast<BillMemberEntity?>().firstWhere(
          (m) => currentUserId != null && m?.userId.isNotEmpty == true && m?.userId == currentUserId,
          orElse: () => null,
        );
    if (myMember != null && bill.creditorMemberId.isNotEmpty) {
      return myMember.memberId == bill.creditorMemberId;
    }
    return false;
  }

  /// Tính toán số tiền thực tế của user hiện tại từ breakdown chính thức
  BillShareBreakdownEntity? get myShare {
    if (breakdown.isEmpty) return null;
    return breakdown.firstWhere(
      (b) => (currentUserId != null && b.userId == currentUserId) || b.memberId == bill.creditorMemberId,
      orElse: () => breakdown.first,
    );
  }

  /// Số tiền thực tế/tạm tính của user hiện tại (ưu tiên breakdown BE, nếu chưa có thì tạm tính trên client)
  int get myShareAmount {
    if (breakdown.isNotEmpty && myShare != null) {
      return myShare!.finalAmount;
    }

    if (bill.members.isEmpty) {
      return computedTotal;
    }

    final myMember = bill.members.cast<BillMemberEntity?>().firstWhere(
          (m) => currentUserId != null && m?.userId.isNotEmpty == true && m?.userId == currentUserId,
          orElse: () => bill.members.cast<BillMemberEntity?>().firstWhere(
                (m) => m?.memberId == bill.creditorMemberId,
                orElse: () => bill.members.isNotEmpty ? bill.members.first : null,
              ),
        );

    if (myMember == null) return computedTotal;

    if (bill.splitMethod == 'even') {
      final selectedIds = activeEvenSplitMemberIds;
      if (!selectedIds.contains(myMember.memberId)) {
        return 0; // Không tham gia chia đều
      }
      final count = selectedIds.length;
      if (count == 0) return computedTotal;
      return (computedTotal / count).round();
    }

    // item_ratio: Tổng các món gán cho user + tỷ lệ phụ thu/VAT/giảm giá
    double myItemSum = 0;
    for (final item in bill.items) {
      final totalWeight = item.assignments.fold<double>(0, (s, a) => s + a.weight);
      final myAssignment = item.assignments.cast<BillItemAssignmentEntity?>().firstWhere(
            (a) => a?.memberId == myMember.memberId,
            orElse: () => null,
          );
      if (myAssignment != null && totalWeight > 0) {
        myItemSum += (item.finalPrice * (myAssignment.weight / totalWeight));
      }
    }

    if (computedNetItemsTotal > 0) {
      final ratio = myItemSum / computedNetItemsTotal;
      final adjustmentShare = (bill.serviceCharge + bill.vat - bill.generalDiscount) * ratio;
      final total = (myItemSum + adjustmentShare).round();
      return total > 0 ? total : 0;
    }

    return myItemSum.round();
  }

  /// Tổng tính toán của tất cả các món gốc (Gross Subtotal = sum(line_total))
  int get computedGrossSubtotal {
    return bill.items.fold(0, (sum, i) => sum + i.lineTotal);
  }

  /// Tổng khuyến mãi theo từng món (sum(discount_amount))
  int get computedTotalItemDiscount {
    return bill.items.fold(0, (sum, i) => sum + i.discountAmount);
  }

  /// Tổng tiền món thực tế sau giảm giá riêng (sum(final_price))
  int get computedNetItemsTotal {
    return computedGrossSubtotal - computedTotalItemDiscount;
  }

  /// Tổng tính toán toàn bộ hoá đơn = Net Items + Service Charge + VAT - General Discount
  int get computedTotal {
    final total = computedNetItemsTotal + bill.serviceCharge + bill.vat - bill.generalDiscount;
    return total > 0 ? total : 0;
  }

  /// Delta chênh lệch giữa tổng tính toán và tổng hóa đơn
  int get deltaTotal {
    return computedTotal - bill.total;
  }

  /// Danh sách các món chưa được gán cho bất kỳ thành viên nào
  List<BillItemEntity> get unassignedItems {
    return bill.items.where((i) => i.assignments.isEmpty).toList();
  }
}

class BillDetailNotifier extends StateNotifier<BillDetailState> {
  final BillRepository _repository;

  BillDetailNotifier(this._repository, BillDetailEntity initialBill)
      : super(
          BillDetailState(
            bill: initialBill,
          ),
        ) {
    final splitMethod = initialBill.splitMethod.isNotEmpty ? initialBill.splitMethod : 'item_ratio';
    final isEven = splitMethod == 'even';
    final effectiveItems = initialBill.items.map((item) {
      if (isEven && item.assignments.isEmpty) {
        return item.copyWith(assignments: _buildEvenAssignments(initialBill.members));
      }
      return item;
    }).toList();

    final syncedBill = _syncBillWithItems(
      initialBill.copyWith(splitMethod: splitMethod),
      effectiveItems,
    );
    final effectiveMembers = initialBill.members;

    state = state.copyWith(
      bill: syncedBill,
      breakdown: _enrichBreakdown(initialBill.breakdown, effectiveMembers, initialBill.creditorMemberId),
    );
  }

  static List<BillShareBreakdownEntity> _enrichBreakdown(
    List<BillShareBreakdownEntity> list,
    List<BillMemberEntity> members,
    String creditorMemberId,
  ) {
    if (list.isEmpty) return list;
    return list.map((item) {
      final member = members.firstWhere(
        (m) => m.memberId == item.memberId,
        orElse: () => BillMemberEntity(
          memberId: item.memberId,
          userId: item.userId,
          displayName: item.displayName,
          avatarUrl: item.avatarUrl,
        ),
      );
      final isCreditor = item.memberId == creditorMemberId;
      return item.copyWith(
        userId: member.userId.isNotEmpty ? member.userId : item.userId,
        displayName: member.displayName.isNotEmpty && member.displayName != 'Thành viên'
            ? member.displayName
            : item.displayName,
        avatarUrl: member.avatarUrl ?? item.avatarUrl,
        isCreditor: isCreditor,
      );
    }).toList();
  }

  static List<BillItemAssignmentEntity> _buildEvenAssignments(List<BillMemberEntity> members) {
    if (members.isEmpty) return const [];
    final count = members.length;
    return members.map((m) {
      return BillItemAssignmentEntity(
        memberId: m.memberId,
        userId: m.userId,
        displayName: m.displayName,
        avatarUrl: m.avatarUrl,
        weight: 1.0 / count,
      );
    }).toList();
  }

  static List<BillItemEntity> _buildEvenItems(List<BillItemEntity> items, List<BillMemberEntity> members) {
    final evenAssignments = _buildEvenAssignments(members);
    return items.map((item) {
      return item.copyWith(assignments: List<BillItemAssignmentEntity>.from(evenAssignments));
    }).toList();
  }

  static BillDetailEntity _syncBillWithItems(
    BillDetailEntity currentBill,
    List<BillItemEntity> items, {
    int? serviceCharge,
    int? vat,
    int? generalDiscount,
    int? total,
  }) {
    final sCharge = serviceCharge ?? currentBill.serviceCharge;
    final v = vat ?? currentBill.vat;
    final gDiscount = generalDiscount ?? currentBill.generalDiscount;

    final grossSubtotal = items.fold(0, (sum, i) => sum + i.lineTotal);
    final totalItemDiscount = items.fold(0, (sum, i) => sum + i.discountAmount);

    return currentBill.copyWith(
      items: items,
      subtotal: grossSubtotal,
      totalItemDiscount: totalItemDiscount,
      serviceCharge: sCharge,
      vat: v,
      generalDiscount: gDiscount,
      total: total ?? currentBill.total,
    );
  }

  void setCurrentUserId(String userId) {
    state = state.copyWith(currentUserId: userId);
  }

  /// Tải dữ liệu hoá đơn và danh sách thành viên nhóm từ API
  Future<void> loadBillDetail({
    required String billId,
    required String groupId,
  }) async {
    state = state.copyWith(isLoading: true);

    // 1. Tải danh sách thành viên nhóm
    final membersResult = await _repository.getGroupMembers(groupId: groupId);
    List<BillMemberEntity> members = [];
    membersResult.match(
      (failure) => null,
      (mList) => members = mList,
    );

    // 2. Nếu là hoá đơn mới chưa lưu trên DB (billId rỗng hoặc bắt đầu bằng draft-):
    // Chỉ cập nhật danh sách thành viên nhóm để gán người ăn, KHÔNG gọi GET bill lên server
    if (billId.isEmpty || billId.startsWith('draft-')) {
      final effectiveMembers = members.isNotEmpty ? members : state.bill.members;
      final splitMethod = state.bill.splitMethod.isNotEmpty ? state.bill.splitMethod : 'item_ratio';
      final isEven = splitMethod == 'even';

      // Tự động gán Chủ chi (Creditor) là user hiện tại hoặc Captain nhóm
      String creditorId = state.bill.creditorMemberId;
      String creditorName = state.bill.creditorName;

      final currentMember = effectiveMembers.cast<BillMemberEntity?>().firstWhere(
            (m) => m?.userId.isNotEmpty == true && m?.userId == state.currentUserId,
            orElse: () => null,
          );
      final captainMember = effectiveMembers.cast<BillMemberEntity?>().firstWhere(
            (m) => m?.role == 'captain',
            orElse: () => null,
          );

      final selectedCreditor = currentMember ?? captainMember ?? (effectiveMembers.isNotEmpty ? effectiveMembers.first : null);
      if (selectedCreditor != null && (creditorId.isEmpty || !effectiveMembers.any((m) => m.memberId == creditorId))) {
        creditorId = selectedCreditor.memberId;
        creditorName = selectedCreditor.displayName;
      }

      final processedItems = state.bill.items.map((item) {
        if (isEven && item.assignments.isEmpty) {
          return item.copyWith(assignments: _buildEvenAssignments(effectiveMembers));
        }
        return item;
      }).toList();

      final syncedBill = _syncBillWithItems(
        state.bill.copyWith(
          members: effectiveMembers,
          creditorMemberId: creditorId,
          creditorName: creditorName,
          splitMethod: splitMethod,
        ),
        processedItems,
      );

      state = state.copyWith(
        bill: syncedBill,
        isLoading: false,
        isDirty: state.bill.items.isNotEmpty,
      );
      return;
    }

    // 3. Tải chi tiết hoá đơn đã lưu từ server (khi billId là UUID thực tế)
    final billResult = await _repository.getBillDetail(billId: billId, groupId: groupId);
    billResult.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (bill) {
        final effectiveMembers = members.isNotEmpty ? members : bill.members;
        final splitMethod = bill.splitMethod.isNotEmpty ? bill.splitMethod : 'item_ratio';
        final isEven = splitMethod == 'even';

        final processedItems = bill.items.map((item) {
          if (isEven && item.assignments.isEmpty) {
            return item.copyWith(assignments: _buildEvenAssignments(effectiveMembers));
          }
          return item;
        }).toList();

        String creditorName = bill.creditorName;
        if (creditorName.isEmpty || creditorName == 'Chủ hoá đơn') {
          final matchedCreditor = effectiveMembers.cast<BillMemberEntity?>().firstWhere(
                (m) => m?.memberId == bill.creditorMemberId || (state.currentUserId != null && m?.userId == state.currentUserId),
                orElse: () => effectiveMembers.cast<BillMemberEntity?>().firstWhere(
                      (m) => m?.role == 'captain',
                      orElse: () => effectiveMembers.isNotEmpty ? effectiveMembers.first : null,
                    ),
              );
          if (matchedCreditor != null) {
            creditorName = matchedCreditor.displayName;
          }
        }

        final syncedBill = _syncBillWithItems(
          bill.copyWith(
            members: effectiveMembers,
            creditorName: creditorName,
            splitMethod: splitMethod,
          ),
          processedItems,
        );

        state = state.copyWith(
          bill: syncedBill,
          breakdown: _enrichBreakdown(bill.breakdown, effectiveMembers, syncedBill.creditorMemberId),
          isLoading: false,
          isDirty: false,
        );
      },
    );
  }

  /// Kích hoạt tiến trình tải ảnh & gọi AI OCR
  Future<void> runOcrProcess({
    required String groupId,
    required List<CapturedBillPhoto> photos,
    String? merchantName,
  }) async {
    if (photos.isEmpty) return;

    state = state.copyWith(
      isOcrScanning: true,
      ocrScanStep: 'Đang tải ảnh biên lai lên máy chủ...',
      clearOcrCandidate: true,
    );

    // 1. Tải trước danh sách thành viên nhóm nếu chưa có
    if (state.bill.members.isEmpty) {
      final membersResult = await _repository.getGroupMembers(groupId: groupId);
      membersResult.match(
        (failure) => null,
        (mList) {
          state = state.copyWith(
            bill: state.bill.copyWith(members: mList),
          );
        },
      );
    }

    state = state.copyWith(
      ocrScanStep: 'AI Llama đang bóc tách món ăn & số tiền...',
    );

    final result = await _repository.createBillWithPhotos(
      groupId: groupId,
      merchantName: merchantName ?? state.bill.merchantName ?? 'Hoá đơn chi tiêu',
      photos: photos,
    );

    result.match(
      (failure) {
        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrErrorMessage: failure.message,
        );
      },
      (candidateBill) {
        final enrichedCandidate = candidateBill.copyWith(
          members: candidateBill.members.isNotEmpty ? candidateBill.members : state.bill.members,
          photos: photos,
        );

        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrCandidate: enrichedCandidate,
        );
      },
    );
  }

  /// Áp dụng kết quả OCR vào hoá đơn chính (mặc định các món chưa gán để người dùng tự chọn)
  void applyOcrCandidate() {
    if (state.ocrCandidate == null) return;
    final candidate = state.ocrCandidate!;
    final effectiveMembers = candidate.members.isNotEmpty ? candidate.members : state.bill.members;

    final candidateItems = candidate.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final it = entry.value;
      final effectiveId = it.id.isNotEmpty
          ? it.id
          : 'ocr-item-${DateTime.now().microsecondsSinceEpoch}-$idx';
      return it.copyWith(
        id: effectiveId,
        position: idx,
        assignments: const [], // Mặc định bỏ chọn tất cả mọi người
      );
    }).toList();

    final isEven = state.bill.splitMethod == 'even';
    final activeItems = isEven ? _buildEvenItems(candidateItems, effectiveMembers) : candidateItems;

    String creditorId = candidate.creditorMemberId.isNotEmpty ? candidate.creditorMemberId : state.bill.creditorMemberId;
    String creditorName = candidate.creditorName;

    if (creditorName.isEmpty || creditorName == 'Chủ hoá đơn') {
      final matchedCreditor = effectiveMembers.cast<BillMemberEntity?>().firstWhere(
            (m) => m?.memberId == creditorId || (state.currentUserId != null && m?.userId == state.currentUserId),
            orElse: () => effectiveMembers.cast<BillMemberEntity?>().firstWhere(
                  (m) => m?.role == 'captain',
                  orElse: () => effectiveMembers.isNotEmpty ? effectiveMembers.first : null,
                ),
          );
      if (matchedCreditor != null) {
        creditorId = matchedCreditor.memberId;
        creditorName = matchedCreditor.displayName;
      }
    }

    final updatedBill = _syncBillWithItems(
      state.bill.copyWith(
        id: candidate.id.isNotEmpty ? candidate.id : state.bill.id,
        creditorMemberId: creditorId,
        creditorName: creditorName,
        merchantName: candidate.merchantName?.isNotEmpty == true ? candidate.merchantName : state.bill.merchantName,
        billDate: candidate.billDate ?? state.bill.billDate,
        serviceCharge: candidate.serviceCharge,
        vat: candidate.vat,
        generalDiscount: candidate.generalDiscount,
        members: effectiveMembers,
        version: candidate.version,
      ),
      activeItems,
      total: candidate.total,
    );

    state = state.copyWith(
      bill: updatedBill,
      clearOcrCandidate: true,
      successMessage: 'Đã áp dụng ${candidateItems.length} món từ kết quả OCR vào hoá đơn!',
    );
  }

  /// Bỏ qua / Huỷ OCR candidate (người dùng chọn tự nhập tay)
  void dismissOcrCandidate() {
    state = state.copyWith(
      clearOcrCandidate: true,
      isOcrScanning: false,
    );
  }

  /// Đổi chế độ chia tiền: Theo món (`item_ratio`) vs Chia đều (`even`)
  void setSplitMode(String mode) {
    if (state.bill.splitMethod == mode) return;

    if (mode == 'even') {
      // Chuyển sang Chia đều: gán các thành viên tham gia chia đều vào tất cả các món
      final targetMemberIds = state.activeEvenSplitMemberIds;
      final selectedMembers = state.bill.members.where((m) => targetMemberIds.contains(m.memberId)).toList();
      final evenItems = _buildEvenItems(state.bill.items, selectedMembers.isNotEmpty ? selectedMembers : state.bill.members);
      final updatedBill = _syncBillWithItems(
        state.bill.copyWith(splitMethod: 'even'),
        evenItems,
      );
      state = state.copyWith(
        bill: updatedBill,
        isDirty: true,
      );
    } else {
      // Chuyển sang Chia theo món: GIỮ NGUYÊN bộ data phân bổ món ăn hiện tại (không xoá)
      final updatedBill = _syncBillWithItems(
        state.bill.copyWith(splitMethod: 'item_ratio'),
        state.bill.items,
      );
      state = state.copyWith(
        bill: updatedBill,
        isDirty: true,
      );
    }
  }

  /// Cập nhật danh sách thành viên tham gia chia đều
  void setEvenSplitMembers(Set<String> memberIds) {
    if (memberIds.isEmpty) return;
    final selectedMembers = state.bill.members.where((m) => memberIds.contains(m.memberId)).toList();
    final evenItems = _buildEvenItems(state.bill.items, selectedMembers);
    final updatedBill = _syncBillWithItems(
      state.bill.copyWith(splitMethod: 'even'),
      evenItems,
    );
    state = state.copyWith(
      bill: updatedBill,
      evenSplitMemberIds: memberIds,
      isDirty: true,
    );
  }

  /// Bật/Tắt gán một thành viên vào một món ăn cụ thể (chế độ chia theo món)
  void toggleMemberAssignment(String itemId, String memberId) {
    final member = state.bill.members.firstWhere(
      (m) => m.memberId == memberId,
      orElse: () => BillMemberEntity(memberId: memberId, userId: '', displayName: 'Thành viên'),
    );

    final updatedItems = state.bill.items.map((item) {
      if (item.id != itemId) return item;

      final existingAssignments = List<BillItemAssignmentEntity>.from(item.assignments);
      final index = existingAssignments.indexWhere((a) => a.memberId == memberId);

      if (index >= 0) {
        existingAssignments.removeAt(index);
      } else {
        existingAssignments.add(
          BillItemAssignmentEntity(
            memberId: memberId,
            userId: member.userId,
            displayName: member.displayName,
            avatarUrl: member.avatarUrl,
          ),
        );
      }

      final count = existingAssignments.length;
      final reweighted = existingAssignments.map((a) {
        return a.copyWith(weight: count > 0 ? (1.0 / count) : 1.0);
      }).toList();

      return item.copyWith(assignments: reweighted);
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Gán tất cả thành viên trong nhóm vào món này (chế độ chia theo món)
  void assignAllMembersToItem(String itemId) {
    final allMembers = state.bill.members;
    final evenAssignments = _buildEvenAssignments(allMembers);

    final updatedItems = state.bill.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(assignments: List<BillItemAssignmentEntity>.from(evenAssignments));
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Cập nhật thông tin món ăn (tên, số lượng, đơn giá, chiết khấu riêng)
  void updateItem(BillItemEntity item) {
    final isEven = state.bill.splitMethod == 'even';
    final effectiveItem = isEven
        ? item.copyWith(assignments: _buildEvenAssignments(state.bill.members))
        : item;

    final updatedItems = state.bill.items.map((i) {
      if (i.id != item.id) return i;
      return effectiveItem;
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Thêm món mới vào hoá đơn
  void addItem(BillItemEntity newItem) {
    final isEven = state.bill.splitMethod == 'even';
    final effectiveItem = isEven
        ? newItem.copyWith(assignments: _buildEvenAssignments(state.bill.members))
        : newItem;

    final updatedItems = [...state.bill.items, effectiveItem];
    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Xoá món khỏi hoá đơn
  void deleteItem(String itemId) {
    final updatedItems = state.bill.items.where((i) => i.id != itemId).toList();
    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Cập nhật Thuế, Phí, Khuyến mãi chung và Tổng cộng
  void setAdjustments({
    int? serviceCharge,
    int? vat,
    int? generalDiscount,
    int? total,
  }) {
    final updatedBill = _syncBillWithItems(
      state.bill,
      state.bill.items,
      serviceCharge: serviceCharge,
      vat: vat,
      generalDiscount: generalDiscount,
      total: total,
    );

    state = state.copyWith(
      bill: updatedBill,
      isDirty: true,
    );
  }

  /// Cập nhật tên quán / địa điểm
  void setMerchantName(String name) {
    if (state.bill.merchantName == name) return;
    state = state.copyWith(
      bill: state.bill.copyWith(merchantName: name),
      isDirty: true,
    );
  }

  /// Cân bằng tổng hoá đơn: Đặt `total` thành `computedTotal`
  void balanceTotalToComputed() {
    state = state.copyWith(
      bill: state.bill.copyWith(total: state.computedTotal),
      isDirty: true,
    );
  }

  /// Thêm phụ thu bù phần thiếu
  void addAdjustmentItem(int amount, {String name = 'Phụ thu / Điều chỉnh'}) {
    final newItem = BillItemEntity(
      id: 'adj-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      unitPrice: amount,
      lineTotal: amount,
      finalPrice: amount,
      assignments: state.bill.splitMethod == 'even' ? _buildEvenAssignments(state.bill.members) : const [],
    );
    addItem(newItem);
  }

  /// Lưu bản nháp lên server và nhận kết quả phân bổ chính thức từ Backend
  Future<bool> saveDraft() async {
    state = state.copyWith(isSaving: true);

    final isNewBill = state.bill.id.isEmpty || state.bill.id.startsWith('draft-');

    if (isNewBill) {
      final result = await _repository.createManualBill(
        groupId: state.bill.groupId,
        merchantName: state.bill.merchantName ?? 'Hoá đơn chi tiêu',
        total: state.bill.total,
        items: state.bill.items,
      );

      return result.match(
        (failure) {
          state = state.copyWith(
            isSaving: false,
            errorMessage: 'Tạo hoá đơn thất bại: ${failure.message}',
          );
          return false;
        },
        (createdBill) {
          final syncedBill = _syncBillWithItems(
            createdBill.copyWith(
              members: state.bill.members,
              photos: state.bill.photos,
            ),
            createdBill.items,
          );
          state = state.copyWith(
            bill: syncedBill,
            breakdown: _enrichBreakdown(createdBill.breakdown, state.bill.members, syncedBill.creditorMemberId),
            isSaving: false,
            isDirty: false,
            successMessage: 'Đã tạo hoá đơn nháp thành công!',
          );
          return true;
        },
      );
    }

    final payload = {
      'merchant_name': state.bill.merchantName,
      'subtotal': state.computedGrossSubtotal,
      'service_charge': state.bill.serviceCharge,
      'vat': state.bill.vat,
      'discount': state.computedTotalItemDiscount + state.bill.generalDiscount,
      'total': state.bill.total,
      'split_method': state.bill.splitMethod,
      'version': state.bill.version,
      'items': state.bill.items.map((i) => i.toJson()).toList(),
    };

    final result = await _repository.updateDraftBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      payload: payload,
    );

    return result.match(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Lưu nháp thất bại: ${failure.message}',
        );
        return false;
      },
      (updatedBill) {
        final existingItems = state.bill.items;
        final resolvedItems = updatedBill.items.isNotEmpty ? updatedBill.items : existingItems;
        final syncedBill = _syncBillWithItems(
          updatedBill.copyWith(
            items: resolvedItems,
            members: state.bill.members,
            photos: state.bill.photos,
          ),
          resolvedItems,
        );
        state = state.copyWith(
          bill: syncedBill,
          breakdown: _enrichBreakdown(
            updatedBill.breakdown.isNotEmpty ? updatedBill.breakdown : state.breakdown,
            state.bill.members,
            syncedBill.creditorMemberId,
          ),
          isSaving: false,
          isDirty: false,
          successMessage: 'Đã lưu bản nháp và cập nhật phân bổ từ máy chủ!',
        );
        return true;
      },
    );
  }

  /// Gọi API Backend (POST /bills/calculate hoặc POST /bills/{id}/calculate) để BE tính và trả về kết quả phân bổ
  Future<List<BillShareBreakdownEntity>?> calculateBreakdown() async {
    state = state.copyWith(isCalculatingBreakdown: true);

    final payload = {
      'group_id': state.bill.groupId,
      'merchant_name': state.bill.merchantName,
      'subtotal': state.computedGrossSubtotal,
      'service_charge': state.bill.serviceCharge,
      'vat': state.bill.vat,
      'discount': state.computedTotalItemDiscount + state.bill.generalDiscount,
      'total': state.bill.total,
      'split_method': state.bill.splitMethod,
      'creditor_member_id': state.bill.creditorMemberId,
      'items': state.bill.items.map((i) => i.toJson()).toList(),
    };

    final result = await _repository.calculateBreakdown(
      billId: state.bill.id.isNotEmpty ? state.bill.id : null,
      groupId: state.bill.groupId,
      payload: payload,
    );

    return result.match(
      (failure) {
        state = state.copyWith(
          isCalculatingBreakdown: false,
          errorMessage: 'Tính toán phân bổ thất bại: ${failure.message}',
        );
        return null;
      },
      (breakdownList) {
        final enrichedList = _enrichBreakdown(breakdownList, state.bill.members, state.bill.creditorMemberId);
        state = state.copyWith(
          breakdown: enrichedList,
          isCalculatingBreakdown: false,
        );
        return enrichedList;
      },
    );
  }

  /// Tải bảng phân bổ chính thức từ Backend khi người dùng bấm nút Phân bổ
  Future<List<BillShareBreakdownEntity>> fetchOfficialBreakdown() async {
    final breakdown = await calculateBreakdown();
    return breakdown ?? state.breakdown;
  }

  /// Thực hiện riêng bước Đối soát (Review Bill) chuyển status từ draft -> reviewed
  Future<bool> reviewBillOnly() async {
    state = state.copyWith(isSaving: true);

    // 1. Luôn lưu nháp dữ liệu mới nhất trước khi đối soát
    final saved = await saveDraft();
    if (!saved) {
      state = state.copyWith(isSaving: false);
      return false;
    }

    // 2. Bước Đối soát (Review Bill)
    final reviewResult = await _repository.reviewBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: state.bill.version,
    );

    return reviewResult.match(
      (failure) {
        String friendlyError = failure.message;
        if (friendlyError.contains('ITEM_UNASSIGNED') || friendlyError.contains('item unassigned')) {
          friendlyError = 'Có món ăn chưa được gán cho thành viên nào. Vui lòng chọn người ăn cho tất cả các món.';
        } else if (friendlyError.contains('CREDITOR_REQUIRED') || friendlyError.contains('creditor required')) {
          friendlyError = 'Vui lòng chọn Người thanh toán (Chủ chi) trước khi chốt hoá đơn.';
        } else if (friendlyError.contains('SUBTOTAL_MISMATCH') || friendlyError.contains('subtotal mismatch')) {
          friendlyError = 'Tổng tiền các món không khớp với tiền hàng tạm tính.';
        } else if (friendlyError.contains('TOTAL_MISMATCH') || friendlyError.contains('total mismatch')) {
          friendlyError = 'Tổng thanh toán không khớp với công thức tiền món + phí/thuế - giảm giá.';
        } else if (friendlyError.contains('DISCOUNT_EXCEEDS_BILL') || friendlyError.contains('discount exceeds')) {
          friendlyError = 'Tiền giảm giá vượt quá tổng giá trị hoá đơn.';
        } else if (friendlyError.contains('INACTIVE_MEMBER_ASSIGNED')) {
          friendlyError = 'Có thành viên đã rời nhóm trong danh sách chia tiền.';
        }

        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Đối soát hoá đơn không đạt: $friendlyError',
        );
        return false;
      },
      (bill) {
        final existingItems = state.bill.items;
        final resolvedItems = bill.items.isNotEmpty ? bill.items : existingItems;
        state = state.copyWith(
          isSaving: false,
          bill: _syncBillWithItems(
            bill.copyWith(
              items: resolvedItems,
              members: state.bill.members,
              photos: state.bill.photos,
            ),
            resolvedItems,
          ),
          breakdown: _enrichBreakdown(
            bill.breakdown.isNotEmpty ? bill.breakdown : state.breakdown,
            state.bill.members,
            state.bill.creditorMemberId,
          ),
          isDirty: false,
          successMessage: 'Hoá đơn đã được đối soát hợp lệ! Sẵn sàng để Trưởng nhóm chốt sổ.',
        );
        return true;
      },
    );
  }

  /// Chốt sổ hoá đơn (Tự động lưu nháp -> Đối soát Review -> Chốt sổ Finalize)
  Future<bool> finalizeBill() async {
    state = state.copyWith(isFinalizing: true);

    // 1. Luôn lưu nháp dữ liệu mới nhất trước khi đối soát
    final saved = await saveDraft();
    if (!saved) {
      state = state.copyWith(isFinalizing: false);
      return false;
    }

    // 2. Bước Đối soát (Review Bill) để chuyển status từ draft -> reviewed
    final reviewResult = await _repository.reviewBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: state.bill.version,
    );

    final reviewedBill = reviewResult.match(
      (failure) {
        String friendlyError = failure.message;
        if (friendlyError.contains('ITEM_UNASSIGNED') || friendlyError.contains('item unassigned')) {
          friendlyError = 'Có món ăn chưa được gán cho thành viên nào. Vui lòng chọn người ăn cho tất cả các món.';
        } else if (friendlyError.contains('CREDITOR_REQUIRED') || friendlyError.contains('creditor required')) {
          friendlyError = 'Vui lòng chọn Người thanh toán (Chủ chi) trước khi chốt hoá đơn.';
        } else if (friendlyError.contains('SUBTOTAL_MISMATCH') || friendlyError.contains('subtotal mismatch')) {
          friendlyError = 'Tổng tiền các món không khớp với tiền hàng tạm tính.';
        } else if (friendlyError.contains('TOTAL_MISMATCH') || friendlyError.contains('total mismatch')) {
          friendlyError = 'Tổng thanh toán không khớp với công thức tiền món + phí/thuế - giảm giá.';
        } else if (friendlyError.contains('DISCOUNT_EXCEEDS_BILL') || friendlyError.contains('discount exceeds')) {
          friendlyError = 'Tiền giảm giá vượt quá tổng giá trị hoá đơn.';
        } else if (friendlyError.contains('INACTIVE_MEMBER_ASSIGNED')) {
          friendlyError = 'Có thành viên đã rời nhóm trong danh sách chia tiền.';
        }

        state = state.copyWith(
          isFinalizing: false,
          errorMessage: 'Đối soát hoá đơn không đạt: $friendlyError',
        );
        return null;
      },
      (bill) {
        final existingItems = state.bill.items;
        final resolvedItems = bill.items.isNotEmpty ? bill.items : existingItems;
        state = state.copyWith(
          bill: _syncBillWithItems(
            bill.copyWith(
              items: resolvedItems,
              members: state.bill.members,
              photos: state.bill.photos,
            ),
            resolvedItems,
          ),
          breakdown: _enrichBreakdown(
            bill.breakdown.isNotEmpty ? bill.breakdown : state.breakdown,
            state.bill.members,
            state.bill.creditorMemberId,
          ),
        );
        return bill;
      },
    );

    if (reviewedBill == null) {
      return false;
    }

    // 3. Bước Chốt sổ (Finalize Bill) chính thức ghi nợ cho nhóm
    final finalizeResult = await _repository.finalizeBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: reviewedBill.version,
    );

    return finalizeResult.match(
      (failure) {
        state = state.copyWith(
          isFinalizing: false,
          errorMessage: 'Chốt hoá đơn thất bại: ${failure.message}',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isFinalizing: false,
          bill: state.bill.copyWith(status: 'finalized'),
          successMessage: 'Hoá đơn đã được chốt sổ thành công!',
        );
        return true;
      },
    );
  }

  /// Huỷ hoá đơn đã chốt (Chỉ Trưởng nhóm có quyền)
  Future<bool> voidBill({required String reason}) async {
    if (reason.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng nhập lý do huỷ hoá đơn.',
      );
      return false;
    }

    state = state.copyWith(isVoiding: true);

    final result = await _repository.voidBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: state.bill.version,
      reason: reason.trim(),
    );

    return result.match(
      (failure) {
        String friendlyError = failure.message;
        if (friendlyError.contains('BILL_ALREADY_VOIDED') || friendlyError.contains('already voided')) {
          friendlyError = 'Hoá đơn này đã bị huỷ trước đó.';
        } else if (friendlyError.contains('PAYMENT_ALREADY_STARTED') || friendlyError.contains('payment already started')) {
          friendlyError = 'Không thể huỷ vì đã có thành viên bắt đầu thanh toán cho hoá đơn này.';
        } else if (friendlyError.contains('CAPTAIN_REQUIRED') || friendlyError.contains('captain required')) {
          friendlyError = 'Chỉ Trưởng nhóm mới có quyền huỷ hoá đơn đã chốt.';
        } else if (friendlyError.contains('VERSION_CONFLICT') || friendlyError.contains('version conflict')) {
          friendlyError = 'Dữ liệu hoá đơn đã bị thay đổi, vui lòng tải lại trang.';
        } else if (friendlyError.contains('GROUP_ARCHIVED') || friendlyError.contains('group archived')) {
          friendlyError = 'Nhóm này đã bị giải tán.';
        }

        state = state.copyWith(
          isVoiding: false,
          errorMessage: 'Huỷ hoá đơn thất bại: $friendlyError',
        );
        return false;
      },
      (voidedBill) {
        final existingItems = state.bill.items;
        final resolvedItems = voidedBill.items.isNotEmpty ? voidedBill.items : existingItems;
        final syncedBill = _syncBillWithItems(
          voidedBill.copyWith(
            status: 'voided',
            items: resolvedItems,
            members: state.bill.members,
            photos: state.bill.photos,
          ),
          resolvedItems,
        );

        state = state.copyWith(
          isVoiding: false,
          bill: syncedBill,
          breakdown: _enrichBreakdown(
            voidedBill.breakdown.isNotEmpty ? voidedBill.breakdown : state.breakdown,
            state.bill.members,
            syncedBill.creditorMemberId,
          ),
          successMessage: 'Đã huỷ hoá đơn thành công!',
        );
        return true;
      },
    );
  }
}

final billDetailNotifierProvider =
    StateNotifierProvider.family<BillDetailNotifier, BillDetailState, BillDetailEntity>(
  (ref, initialBill) {
    final repository = getIt<BillRepository>();
    return BillDetailNotifier(repository, initialBill);
  },
);
