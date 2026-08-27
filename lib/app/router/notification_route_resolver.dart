import '../../../features/groups/presentation/pages/group_detail_page.dart';
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
    _ => null,
  };

  static ResolvedRoute? _batchCompleted(Map<String, dynamic> payload) {
    final groupId = payload['group_id'] as String?;
    if (groupId == null || groupId.isEmpty) return null;
    final batchId = payload['batch_id'] as String?;
    return ResolvedRoute(
      path: AppRoutes.groupDetail(groupId),
      extra: GroupDetailRouteArgs(
        openBatchId: batchId,
        initialTab: GroupHubTab.bills,
      ),
    );
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
