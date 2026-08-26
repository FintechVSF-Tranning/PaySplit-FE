import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_models.dart';

part 'group_sync_models.freezed.dart';
part 'group_sync_models.g.dart';

/// DTO cho giao thức đồng bộ nhóm (`GET /groups/{id}/sync` và
/// `GET /groups/{id}/events`). Hợp đồng tại `PaySplit-BE/docs/openapi.yaml`.

/// Các loại sự kiện backend phát ra. Giá trị khớp đúng hằng số phía Go.
class GroupEventType {
  const GroupEventType._();

  static const String memberJoined = 'member_joined';
  static const String memberReactivated = 'member_reactivated';
  static const String memberLeft = 'member_left';
  static const String memberRemoved = 'member_removed';
  static const String captainTransferred = 'captain_transferred';
  static const String groupRenamed = 'group_renamed';
  static const String groupArchived = 'group_archived';
}

/// Một sự kiện trong nhật ký nhóm.
///
/// [data] để nguyên dạng map vì hình dạng phụ thuộc [type]; nó cũng có thể rỗng
/// khi backend phải cắt payload — khi đó version vẫn tiến và client tự gọi
/// `/sync` để lấy nội dung đầy đủ.
@freezed
class GroupSyncEventModel with _$GroupSyncEventModel {
  const factory GroupSyncEventModel({
    required int version,
    required String type,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _GroupSyncEventModel;

  factory GroupSyncEventModel.fromJson(Map<String, dynamic> json) =>
      _$GroupSyncEventModelFromJson(json);
}

/// Kết quả một lần catch-up. Đúng một trong [events]/[snapshot] có nghĩa, tùy [mode].
@freezed
class GroupSyncResponseModel with _$GroupSyncResponseModel {
  const factory GroupSyncResponseModel({
    required int version,
    required String mode,
    @Default(<GroupSyncEventModel>[]) List<GroupSyncEventModel> events,
    GroupDetailResponseModel? snapshot,
  }) = _GroupSyncResponseModel;

  factory GroupSyncResponseModel.fromJson(Map<String, dynamic> json) =>
      _$GroupSyncResponseModelFromJson(json);

  static const String modeDelta = 'delta';
  static const String modeSnapshot = 'snapshot';
}
