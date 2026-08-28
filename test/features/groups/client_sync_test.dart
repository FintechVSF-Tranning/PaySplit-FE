import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/data/models/client_sync_models.dart';

void main() {
  group('ClientSyncModels', () {
    test('AppConfigModel.fromJson parses correctly', () {
      final json = {
        'realtime_mode': 'supabase',
        'poll_interval_seconds': 15,
        'poll_jitter_percent': 25,
        'max_group_channels': 12,
        'sync_page_limit': 400,
        'sync_max_bytes': 131072,
        'sync_max_pages_per_cycle': 3,
        'supabase_url': 'https://test.supabase.co',
        'supabase_publishable_key': 'sb_pub_123',
      };

      final model = AppConfigModel.fromJson(json);

      expect(model.realtimeMode, 'supabase');
      expect(model.pollIntervalSeconds, 15);
      expect(model.pollJitterPercent, 25);
      expect(model.maxGroupChannels, 12);
      expect(model.syncPageLimit, 400);
      expect(model.syncMaxBytes, 131072);
      expect(model.syncMaxPagesPerCycle, 3);
      expect(model.supabaseUrl, 'https://test.supabase.co');
      expect(model.supabasePublishableKey, 'sb_pub_123');
    });

    test('SyncVersionsModel.fromJson parses aggregates and watermark correctly', () {
      final json = {
        'watermark': 1050,
        'membership_sync_version': 4,
        'aggregates': [
          {
            'group_id': '45781a91-4221-4f1b-85ca-123456789abc',
            'aggregate_type': 'bill',
            'aggregate_id': '98765432-1111-2222-3333-abcdefabcdef',
            'version': 8,
          },
        ],
        'next_cursor': 'test.cursor.sig',
        'has_more': false,
      };

      final model = SyncVersionsModel.fromJson(json);

      expect(model.watermark, 1050);
      expect(model.membershipSyncVersion, 4);
      expect(model.aggregates.length, 1);
      expect(model.aggregates.first.aggregateType, 'bill');
      expect(model.aggregates.first.version, 8);
      expect(model.nextCursor, 'test.cursor.sig');
      expect(model.hasMore, false);
    });
  });
}
