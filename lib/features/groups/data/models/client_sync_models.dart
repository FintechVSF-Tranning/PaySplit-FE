import 'package:equatable/equatable.dart';

/// Cấu hình realtime và sync do server trả về từ GET /api/v1/app-config
class AppConfigModel extends Equatable {
  const AppConfigModel({
    required this.realtimeMode,
    required this.pollIntervalSeconds,
    required this.pollJitterPercent,
    required this.maxGroupChannels,
    required this.syncPageLimit,
    required this.syncMaxBytes,
    required this.syncMaxPagesPerCycle,
    this.supabaseUrl,
    this.supabasePublishableKey,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      realtimeMode: json['realtime_mode'] as String? ?? 'polling',
      pollIntervalSeconds: json['poll_interval_seconds'] as int? ?? 10,
      pollJitterPercent: json['poll_jitter_percent'] as int? ?? 20,
      maxGroupChannels: json['max_group_channels'] as int? ?? 10,
      syncPageLimit: json['sync_page_limit'] as int? ?? 500,
      syncMaxBytes: json['sync_max_bytes'] as int? ?? 262144,
      syncMaxPagesPerCycle: json['sync_max_pages_per_cycle'] as int? ?? 4,
      supabaseUrl: json['supabase_url'] as String?,
      supabasePublishableKey: json['supabase_publishable_key'] as String?,
    );
  }

  final String realtimeMode;
  final int pollIntervalSeconds;
  final int pollJitterPercent;
  final int maxGroupChannels;
  final int syncPageLimit;
  final int syncMaxBytes;
  final int syncMaxPagesPerCycle;
  final String? supabaseUrl;
  final String? supabasePublishableKey;

  @override
  List<Object?> get props => [
        realtimeMode,
        pollIntervalSeconds,
        pollJitterPercent,
        maxGroupChannels,
        syncPageLimit,
        syncMaxBytes,
        syncMaxPagesPerCycle,
        supabaseUrl,
        supabasePublishableKey,
      ];
}

/// Một bản ghi delta aggregate version
class AggregateVersionItemModel extends Equatable {
  const AggregateVersionItemModel({
    required this.groupId,
    required this.aggregateType,
    required this.aggregateId,
    required this.version,
  });

  factory AggregateVersionItemModel.fromJson(Map<String, dynamic> json) {
    return AggregateVersionItemModel(
      groupId: json['group_id'] as String,
      aggregateType: json['aggregate_type'] as String,
      aggregateId: json['aggregate_id'] as String,
      version: json['version'] as int,
    );
  }

  final String groupId;
  final String aggregateType;
  final String aggregateId;
  final int version;

  @override
  List<Object?> get props => [groupId, aggregateType, aggregateId, version];
}

/// Kết quả trả về từ GET /api/v1/sync/versions
class SyncVersionsModel extends Equatable {
  const SyncVersionsModel({
    required this.watermark,
    required this.membershipSyncVersion,
    required this.aggregates,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncVersionsModel.fromJson(Map<String, dynamic> json) {
    final rawAggregates = json['aggregates'] as List<dynamic>? ?? [];
    final aggregates = rawAggregates
        .map((e) => AggregateVersionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return SyncVersionsModel(
      watermark: json['watermark'] as int? ?? 0,
      membershipSyncVersion: json['membership_sync_version'] as int? ?? 0,
      aggregates: aggregates,
      nextCursor: json['next_cursor'] as String? ?? '',
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  final int watermark;
  final int membershipSyncVersion;
  final List<AggregateVersionItemModel> aggregates;
  final String nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => [
        watermark,
        membershipSyncVersion,
        aggregates,
        nextCursor,
        hasMore,
      ];
}
