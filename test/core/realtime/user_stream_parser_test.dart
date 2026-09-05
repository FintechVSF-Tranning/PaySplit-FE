import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/realtime/realtime_interest.dart';
import 'package:paysplit/core/realtime/realtime_interest_registry.dart';
import 'package:paysplit/core/realtime/user_realtime_owner.dart';
import 'package:paysplit/features/groups/data/datasources/group_event_stream_datasource.dart';

void main() {
  test('parseSseLines yields ready then invalidate frames', () async {
    final frames = await parseSseLines(
      Stream.fromIterable([
        'event: ready',
        'data: {"stream_id":"a","timestamp":"2026-09-03T00:00:00Z"}',
        '',
        'event: invalidate',
        'data: {"scope":"home","group_id":"g1","type":"home.balance_changed"}',
        '',
      ]),
    ).toList();
    expect(frames, hasLength(2));
    expect(frames.first.event, 'ready');
    expect(frames.last.event, 'invalidate');
    expect(frames.last.data['type'], 'home.balance_changed');
  });

  test('registry matches group and bill keys independently', () {
    final registry = RealtimeInterestRegistry();
    var homeHits = 0;
    registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.homeGroups(),
        refresh: () async {
          homeHits++;
        },
      ),
    );
    registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.groupDebts('g1'),
        refresh: () async {},
      ),
    );
    expect(registry.matching(surface: 'home.groups'), hasLength(1));
    expect(
      registry.matching(surface: 'group.debts', groupId: 'g1'),
      hasLength(1),
    );
    expect(registry.matching(surface: 'group.debts', groupId: 'g2'), isEmpty);
    expect(homeHits, 0);
  });

  test('registry unregisters on dispose so stale bills are not refreshed', () {
    // covers: AC-17
    final registry = RealtimeInterestRegistry();
    var hits = 0;
    final key = RealtimeInterestKey.billDetail('g1', 'b1');
    registry.register(
      RealtimeInterest(
        key: key,
        refresh: () async {
          hits++;
        },
      ),
    );
    registry.unregister(key);
    expect(
      registry.matching(surface: 'bill.detail', groupId: 'g1', billId: 'b1'),
      isEmpty,
    );
    expect(hits, 0);
  });

  test('bill deletion refreshes the groups index summary', () {
    final registry = RealtimeInterestRegistry();
    final groupsIndex = RealtimeInterest(
      key: RealtimeInterestKey.groupsIndex(),
      refresh: () async {},
    );
    registry.register(groupsIndex);

    final targets = UserRealtimeOwner().targetsFor(
      const SseFrame(
        event: 'invalidate',
        data: {'type': 'bill.deleted', 'group_id': 'g1', 'resource_id': 'b1'},
      ),
      registryOverride: registry,
    );

    expect(targets, contains(groupsIndex));
  });
}
