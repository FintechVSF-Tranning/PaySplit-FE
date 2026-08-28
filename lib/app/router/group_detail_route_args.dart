import '../../../features/groups/domain/entities/group_entity.dart';
import '../../../features/groups/presentation/pages/group_detail_page.dart';

/// Typed arguments for the `/groups/:groupId` route.
///
/// Supports passing an optional [openBatchId] to auto-open the bulk finalize
/// progress sheet, and an [initialTab] to land on a specific Group Hub tab.
class GroupDetailRouteArgs {
  const GroupDetailRouteArgs({this.group, this.openBatchId, this.initialTab});

  /// Pre-fetched group entity. When null, GroupDetailPage builds a fallback
  /// from the path parameter.
  final GroupEntity? group;

  /// When set, the Group Detail page auto-opens the bulk finalize progress
  /// sheet for this batch after loading.
  final String? openBatchId;

  /// Which Group Hub tab to land on. Defaults to bills when null.
  final GroupHubTab? initialTab;
}
