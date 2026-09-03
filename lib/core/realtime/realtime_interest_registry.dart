import 'realtime_interest.dart';

class RealtimeInterestRegistry {
  final Map<RealtimeInterestKey, RealtimeInterest> _interests = {};

  void register(RealtimeInterest interest) {
    _interests[interest.key] = interest;
  }

  void unregister(RealtimeInterestKey key) {
    _interests.remove(key);
  }

  List<RealtimeInterest> matching({
    String? surface,
    String? groupId,
    String? billId,
  }) {
    return _interests.values.where((interest) {
      if (surface != null && interest.key.surface != surface) return false;
      if (groupId != null && interest.key.groupId != groupId) return false;
      if (billId != null && interest.key.billId != billId) return false;
      return true;
    }).toList();
  }

  List<RealtimeInterest> get all => _interests.values.toList();
}
