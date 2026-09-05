import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'realtime_interest.dart';
import 'user_realtime_owner.dart';

void registerRealtimeInterest(
  Ref ref, {
  required RealtimeInterestKey key,
  int Function()? resourceVersion,
  Future<void> Function()? refresh,
  void Function(Map<String, dynamic> frame)? applyRoster,
  Future<void> Function(String groupId)? patchGroup,
}) {
  final registry = ref.read(realtimeInterestRegistryProvider);
  registry.register(
    RealtimeInterest(
      key: key,
      resourceVersion: resourceVersion,
      refresh: refresh,
      applyRoster: applyRoster,
      patchGroup: patchGroup,
    ),
  );
  ref.onDispose(() => registry.unregister(key));
}
