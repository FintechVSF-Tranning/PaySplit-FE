import 'captured_bill_photo.dart';

/// Đại diện cho thành viên trong nhóm tham gia vào hoá đơn
class BillMemberEntity {
  final String memberId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role; // 'captain' | 'member'

  const BillMemberEntity({
    required this.memberId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = 'member',
  });

  BillMemberEntity copyWith({
    String? memberId,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? role,
  }) {
    return BillMemberEntity(
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'TV';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  factory BillMemberEntity.fromJson(Map<String, dynamic> json) {
    return BillMemberEntity(
      memberId: json['membership_id'] as String? ?? json['member_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Thành viên',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'user_id': userId,
      'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'role': role,
    };
  }
}

/// Gán thành viên vào món ăn
class BillItemAssignmentEntity {
  final String memberId;
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final double weight;

  const BillItemAssignmentEntity({
    required this.memberId,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.weight = 1.0,
  });

  BillItemAssignmentEntity copyWith({
    String? memberId,
    String? userId,
    String? displayName,
    String? avatarUrl,
    double? weight,
  }) {
    return BillItemAssignmentEntity(
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      weight: weight ?? this.weight,
    );
  }

  factory BillItemAssignmentEntity.fromJson(Map<String, dynamic> json) {
    return BillItemAssignmentEntity(
      memberId: json['member_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      weight: (json['weight'] is num) ? (json['weight'] as num).toDouble() : 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'weight': weight.toString(),
    };
  }
}

/// Dòng món ăn trên hoá đơn
class BillItemEntity {
  final String id;
  final String name;
  final String quantity;
  final int unitPrice;
  final int lineTotal;
  final int discountAmount;
  final int finalPrice;
  final List<BillItemAssignmentEntity> assignments;
  final int position;

  const BillItemEntity({
    required this.id,
    required this.name,
    this.quantity = '1',
    this.unitPrice = 0,
    required this.lineTotal,
    this.discountAmount = 0,
    required this.finalPrice,
    this.assignments = const [],
    this.position = 0,
  });

  BillItemEntity copyWith({
    String? id,
    String? name,
    String? quantity,
    int? unitPrice,
    int? lineTotal,
    int? discountAmount,
    int? finalPrice,
    List<BillItemAssignmentEntity>? assignments,
    int? position,
  }) {
    final newDiscount = discountAmount ?? this.discountAmount;
    final newLineTotal = lineTotal ?? this.lineTotal;
    return BillItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: newLineTotal,
      discountAmount: newDiscount,
      finalPrice: finalPrice ?? (newLineTotal - newDiscount),
      assignments: assignments ?? this.assignments,
      position: position ?? this.position,
    );
  }

  factory BillItemEntity.fromJson(Map<String, dynamic> json) {
    final lineTot = (json['line_total'] as num?)?.toInt() ?? 0;
    final disc = (json['discount_amount'] as num?)?.toInt() ?? 0;
    final expectedFinalP = (lineTot - disc).clamp(0, lineTot);
    final rawFinalP = (json['final_price'] as num?)?.toInt();
    final finalP = (rawFinalP != null && rawFinalP > 0) ? rawFinalP : expectedFinalP;

    var assignList = <BillItemAssignmentEntity>[];
    if (json['assignments'] is List) {
      assignList = (json['assignments'] as List)
          .map((a) => BillItemAssignmentEntity.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    final rawId = json['id'] as String? ?? json['_id'] as String? ?? '';
    final pos = (json['position'] as num?)?.toInt() ?? 0;
    final effectiveId = rawId.trim().isNotEmpty
        ? rawId.trim()
        : 'item-${DateTime.now().microsecondsSinceEpoch}-$pos';

    final rawQtyStr = json['quantity']?.toString() ?? '1';
    final qtyDouble = double.tryParse(rawQtyStr.replaceAll(',', '.')) ?? 1.0;
    final cleanQtyStr = (qtyDouble == qtyDouble.roundToDouble())
        ? qtyDouble.toInt().toString()
        : qtyDouble.toString();
    final rawUnitPrice = (json['unit_price'] as num?)?.toInt() ?? 0;
    final effectiveUnitPrice = rawUnitPrice > 0
        ? rawUnitPrice
        : (qtyDouble > 0 ? (lineTot / qtyDouble).round() : lineTot);

    return BillItemEntity(
      id: effectiveId,
      name: json['name'] as String? ?? 'Món ăn',
      quantity: cleanQtyStr,
      unitPrice: effectiveUnitPrice,
      lineTotal: lineTot,
      discountAmount: disc,
      finalPrice: finalP,
      assignments: assignList,
      position: pos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'discount_amount': discountAmount,
      'final_price': finalPrice,
      'position': position,
      'assignments': assignments.map((a) => a.toJson()).toList(),
    };
  }
}

/// Kết quả phân bổ tiền cho từng thành viên
class BillShareBreakdownEntity {
  final String memberId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int itemsSubtotal;
  final int serviceShare;
  final int vatShare;
  final int generalDiscountShare;
  final int finalAmount;
  final bool isCreditor;

  const BillShareBreakdownEntity({
    required this.memberId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.itemsSubtotal,
    required this.serviceShare,
    required this.vatShare,
    required this.generalDiscountShare,
    required this.finalAmount,
    this.isCreditor = false,
  });

  BillShareBreakdownEntity copyWith({
    String? memberId,
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? itemsSubtotal,
    int? serviceShare,
    int? vatShare,
    int? generalDiscountShare,
    int? finalAmount,
    bool? isCreditor,
  }) {
    return BillShareBreakdownEntity(
      memberId: memberId ?? this.memberId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      itemsSubtotal: itemsSubtotal ?? this.itemsSubtotal,
      serviceShare: serviceShare ?? this.serviceShare,
      vatShare: vatShare ?? this.vatShare,
      generalDiscountShare: generalDiscountShare ?? this.generalDiscountShare,
      finalAmount: finalAmount ?? this.finalAmount,
      isCreditor: isCreditor ?? this.isCreditor,
    );
  }

  factory BillShareBreakdownEntity.fromJson(Map<String, dynamic> json) {
    return BillShareBreakdownEntity(
      memberId: json['member_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Thành viên',
      avatarUrl: json['avatar_url'] as String?,
      itemsSubtotal: (json['items_subtotal'] as num?)?.toInt() ?? (json['item_subtotal'] as num?)?.toInt() ?? 0,
      serviceShare: (json['service_share'] as num?)?.toInt() ?? (json['service_charge_share'] as num?)?.toInt() ?? 0,
      vatShare: (json['vat_share'] as num?)?.toInt() ?? 0,
      generalDiscountShare: (json['general_discount_share'] as num?)?.toInt() ?? (json['discount_share'] as num?)?.toInt() ?? 0,
      finalAmount: (json['final_amount'] as num?)?.toInt() ?? 0,
      isCreditor: json['is_creditor'] as bool? ?? false,
    );
  }
}

/// Thông tin chi tiết toàn bộ hoá đơn
class BillDetailEntity {
  final String id;
  final String groupId;
  final String groupName;
  final String creditorMemberId;
  final String creditorName;
  final String status; // 'draft' | 'reviewed' | 'finalized' | 'voided'
  final String? merchantName;
  final DateTime? billDate;
  final int subtotal;
  final int serviceCharge;
  final int vat;
  final int totalItemDiscount;
  final int generalDiscount;
  final int total;
  final String splitMethod; // 'item_ratio' | 'even'
  final int version;
  final List<BillItemEntity> items;
  final List<BillMemberEntity> members;
  final List<CapturedBillPhoto> photos;
  final List<String> mismatchCodes;
  final List<BillShareBreakdownEntity> breakdown;

  const BillDetailEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.creditorMemberId,
    required this.creditorName,
    required this.status,
    this.merchantName,
    this.billDate,
    required this.subtotal,
    required this.serviceCharge,
    required this.vat,
    required this.totalItemDiscount,
    required this.generalDiscount,
    required this.total,
    this.splitMethod = 'item_ratio',
    this.version = 1,
    this.items = const [],
    this.members = const [],
    this.photos = const [],
    this.mismatchCodes = const [],
    this.breakdown = const [],
  });

  BillDetailEntity copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? creditorMemberId,
    String? creditorName,
    String? status,
    String? merchantName,
    DateTime? billDate,
    int? subtotal,
    int? serviceCharge,
    int? vat,
    int? totalItemDiscount,
    int? generalDiscount,
    int? total,
    String? splitMethod,
    int? version,
    List<BillItemEntity>? items,
    List<BillMemberEntity>? members,
    List<CapturedBillPhoto>? photos,
    List<String>? mismatchCodes,
    List<BillShareBreakdownEntity>? breakdown,
  }) {
    return BillDetailEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      creditorMemberId: creditorMemberId ?? this.creditorMemberId,
      creditorName: creditorName ?? this.creditorName,
      status: status ?? this.status,
      merchantName: merchantName ?? this.merchantName,
      billDate: billDate ?? this.billDate,
      subtotal: subtotal ?? this.subtotal,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      totalItemDiscount: totalItemDiscount ?? this.totalItemDiscount,
      generalDiscount: generalDiscount ?? this.generalDiscount,
      total: total ?? this.total,
      splitMethod: splitMethod ?? this.splitMethod,
      version: version ?? this.version,
      items: items ?? this.items,
      members: members ?? this.members,
      photos: photos ?? this.photos,
      mismatchCodes: mismatchCodes ?? this.mismatchCodes,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  /// Tên hiển thị người trả tiền: ưu tiên tên đã gán, nếu rỗng thì tra cứu từ danh sách thành viên nhóm
  String get creditorDisplayName {
    if (creditorName.isNotEmpty && creditorName != 'Chủ hoá đơn') {
      return creditorName;
    }
    if (members.isNotEmpty) {
      final matched = members.cast<BillMemberEntity?>().firstWhere(
            (m) => m?.memberId == creditorMemberId,
            orElse: () => null,
          );
      if (matched != null && matched.displayName.isNotEmpty) {
        return matched.displayName;
      }
    }
    return creditorName.isNotEmpty ? creditorName : 'Chủ chi';
  }

  factory BillDetailEntity.fromJson(Map<String, dynamic> json, {String? groupName, List<BillMemberEntity>? members}) {
    final itemsJson = (json['items'] as List?) ?? [];
    var itemsList = itemsJson.map((i) => BillItemEntity.fromJson(i as Map<String, dynamic>)).toList();

    var candidateJson = json['candidate'] as Map<String, dynamic>?;
    if (candidateJson == null && json['ocr_job'] is Map<String, dynamic>) {
      final ocrJob = json['ocr_job'] as Map<String, dynamic>;
      if (ocrJob['candidate'] is Map<String, dynamic>) {
        candidateJson = ocrJob['candidate'] as Map<String, dynamic>;
      }
    }
    if (candidateJson == null && json['ocr_jobs'] is List) {
      for (final job in (json['ocr_jobs'] as List)) {
        if (job is Map<String, dynamic> && job['candidate'] is Map<String, dynamic>) {
          candidateJson = job['candidate'] as Map<String, dynamic>;
          break;
        }
      }
    }

    var subtotal = (json['subtotal'] as num?)?.toInt() ?? 0;
    var serviceCharge = (json['service_charge'] as num?)?.toInt() ?? 0;
    var vat = (json['vat'] as num?)?.toInt() ?? 0;
    var totalItemDiscount = (json['total_item_discount'] as num?)?.toInt() ?? 0;
    var generalDiscount = (json['general_discount'] as num?)?.toInt() ?? 0;
    var total = (json['total'] as num?)?.toInt() ?? 0;
    var merchantName = json['merchant_name'] as String?;

    if (candidateJson != null && candidateJson['merchant_name'] is String) {
      final candMerchant = (candidateJson['merchant_name'] as String).trim();
      if (candMerchant.isNotEmpty) {
        merchantName = candMerchant;
      }
    }

    if (itemsList.isEmpty && candidateJson != null) {
      subtotal = (candidateJson['subtotal'] as num?)?.toInt() ?? subtotal;
      serviceCharge = (candidateJson['service_charge'] as num?)?.toInt() ?? serviceCharge;
      vat = (candidateJson['vat'] as num?)?.toInt() ?? vat;
      totalItemDiscount = (candidateJson['total_item_discount'] as num?)?.toInt() ?? totalItemDiscount;
      generalDiscount = (candidateJson['general_discount'] as num?)?.toInt() ?? generalDiscount;
      total = (candidateJson['total'] as num?)?.toInt() ?? total;

      if (candidateJson['items'] is List) {
        int pos = 0;
        itemsList = (candidateJson['items'] as List).map((i) {
          final map = Map<String, dynamic>.from(i as Map<String, dynamic>);
          if (map['position'] == null) {
            map['position'] = pos;
          }
          if (map['id'] == null || map['id'].toString().trim().isEmpty) {
            map['id'] = 'ocr-item-${DateTime.now().microsecondsSinceEpoch}-${pos++}';
          } else {
            pos++;
          }
          return BillItemEntity.fromJson(map);
        }).toList();
      }
    }

    final effectiveGroupName = groupName ?? json['group_name'] as String? ?? 'Nhóm chi tiêu';
    final fallbackMerchantName = 'Hoá đơn $effectiveGroupName';

    return BillDetailEntity(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      groupName: effectiveGroupName,
      creditorMemberId: json['creditor_member_id'] as String? ?? '',
      creditorName: json['creditor_name'] as String? ?? 'Chủ hoá đơn',
      status: json['status'] as String? ?? 'draft',
      merchantName: (merchantName != null && merchantName.isNotEmpty) ? merchantName : fallbackMerchantName,
      billDate: json['bill_date'] != null ? DateTime.tryParse(json['bill_date'].toString()) : DateTime.now(),
      subtotal: subtotal,
      serviceCharge: serviceCharge,
      vat: vat,
      totalItemDiscount: totalItemDiscount,
      generalDiscount: generalDiscount,
      total: total,
      splitMethod: json['split_method'] as String? ?? 'item_ratio',
      version: (json['version'] as num?)?.toInt() ?? 1,
      items: itemsList,
      members: members ?? const [],
      mismatchCodes: (json['mismatch_codes'] as List?)?.map((c) => c.toString()).toList() ?? const [],
      breakdown: (json['breakdown'] as List?)
              ?.map((b) => BillShareBreakdownEntity.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
