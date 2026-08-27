import '../../../features/groups/presentation/pages/group_detail_page.dart';
import '../../../features/settlement/presentation/providers/settlement_controller.dart';
import 'app_routes.dart';
import 'group_detail_route_args.dart';

/// Resolves a notification payload into a route the app can navigate to.
///
/// Placed in `app/router/` because it depends on [AppRoutes] and
/// [GroupDetailRouteArgs] — keeping it here avoids `core/` depending on
/// the presentation layer.
class NotificationRouteResolver {
  /// Returns a [ResolvedRoute] if [type] is a known notification type and
  /// [payload] contains sufficient data; returns `null` otherwise.
  ///
  /// Never throws, even when payload is malformed.
  static ResolvedRoute? resolve({
    required String type,
    required Map<String, dynamic> payload,
  }) => switch (type) {
    'bill_bulk_finalize_completed' => _batchCompleted(payload),
    'payment_submitted' ||
    'payment_stalled_confirmation' ||
    'stalled_payment_reminder' => _paymentSubmittedOrStalled(payload),
    'payment_confirmed' => _paymentConfirmed(payload),
    'payment_rejected' ||
    'debt_reminded' ||
    'debt_reminder' ||
    'payment_reminder' ||
    'payment_created' => _debtOrPaymentAction(payload),
    'bill_finalized' ||
    'new_bill' ||
    'created_bill' ||
    'bill_updated' => _billRoute(payload),
    'group_invitation' ||
    'group_invite' ||
    'member_joined' => _groupInviteRoute(payload),
    _ => _fallbackRoute(payload),
  };

  static String? _extractString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) return value;
      if (value != null && value is! Map && value is! List) {
        final str = value.toString().trim();
        if (str.isNotEmpty) return str;
      }
    }
    return null;
  }

  static ResolvedRoute? _batchCompleted(Map<String, dynamic> payload) {
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (groupId == null) return null;
    final batchId = _extractString(payload, const ['batch_id', 'batchId']);
    return ResolvedRoute(
      path: AppRoutes.groupDetail(groupId),
      extra: GroupDetailRouteArgs(
        openBatchId: batchId,
        initialTab: GroupHubTab.bills,
      ),
    );
  }

  static ResolvedRoute? _paymentSubmittedOrStalled(Map<String, dynamic> payload) {
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (groupId != null) {
      return ResolvedRoute(
        path: AppRoutes.groupDetail(groupId),
        extra: const GroupDetailRouteArgs(initialTab: GroupHubTab.debts),
      );
    }
    return const ResolvedRoute(
      path: AppRoutes.settlement,
      extra: SettlementTab.receivable,
    );
  }

  static ResolvedRoute? _paymentConfirmed(Map<String, dynamic> payload) {
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (groupId != null) {
      return ResolvedRoute(
        path: AppRoutes.groupDetail(groupId),
        extra: const GroupDetailRouteArgs(initialTab: GroupHubTab.debts),
      );
    }
    return const ResolvedRoute(
      path: AppRoutes.settlement,
      extra: SettlementTab.history,
    );
  }

  static ResolvedRoute? _debtOrPaymentAction(Map<String, dynamic> payload) {
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (groupId != null) {
      return ResolvedRoute(
        path: AppRoutes.groupDetail(groupId),
        extra: const GroupDetailRouteArgs(initialTab: GroupHubTab.debts),
      );
    }
    return const ResolvedRoute(
      path: AppRoutes.settlement,
      extra: SettlementTab.payable,
    );
  }

  static ResolvedRoute? _billRoute(Map<String, dynamic> payload) {
    final billId = _extractString(payload, const ['bill_id', 'billId']);
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (billId != null) {
      return ResolvedRoute(
        path: AppRoutes.billDetail,
        extra: <String, dynamic>{
          'billId': billId,
          if (groupId != null) 'groupId': groupId,
        },
      );
    }
    if (groupId != null) {
      return ResolvedRoute(
        path: AppRoutes.groupDetail(groupId),
        extra: const GroupDetailRouteArgs(initialTab: GroupHubTab.bills),
      );
    }
    return const ResolvedRoute(
      path: AppRoutes.bills,
      extra: SettlementTab.bills,
    );
  }

  static ResolvedRoute? _groupInviteRoute(Map<String, dynamic> payload) {
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    if (groupId != null) {
      return ResolvedRoute(
        path: AppRoutes.groupDetail(groupId),
        extra: const GroupDetailRouteArgs(initialTab: GroupHubTab.bills),
      );
    }
    return const ResolvedRoute(path: AppRoutes.groups);
  }

  static ResolvedRoute? _fallbackRoute(Map<String, dynamic> payload) {
    final billId = _extractString(payload, const ['bill_id', 'billId']);
    final groupId = _extractString(payload, const ['group_id', 'groupId']);
    final paymentId = _extractString(payload, const ['payment_id', 'paymentId']);

    if (billId != null) {
      return ResolvedRoute(
        path: AppRoutes.billDetail,
        extra: <String, dynamic>{
          'billId': billId,
          if (groupId != null) 'groupId': groupId,
        },
      );
    }
    if (paymentId != null) {
      return const ResolvedRoute(path: AppRoutes.settlement);
    }
    if (groupId != null) {
      return ResolvedRoute(path: AppRoutes.groupDetail(groupId));
    }
    return null;
  }
}

/// A resolved navigation destination from a notification.
class ResolvedRoute {
  const ResolvedRoute({required this.path, this.extra});

  /// The route path to navigate to, e.g. `/groups/abc-123`.
  final String path;

  /// Optional extra data to pass to the route builder.
  final Object? extra;
}
