import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_models.freezed.dart';
part 'group_models.g.dart';

/// DTO cho module `group` của backend. Mọi field dùng snake_case đúng hợp đồng
/// tại `PaySplit-BE/docs/openapi.yaml`; việc quy đổi sang entity nằm ở
/// `group_mapper.dart` để model giữ đúng vai trò "hình dạng JSON".
@freezed
class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String id,
    required String name,
    required String currency,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'bill_submission_locked') @Default(false) bool billSubmissionLocked,
    @JsonKey(name: 'bill_submission_locked_at') DateTime? billSubmissionLockedAt,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) => _$GroupModelFromJson(json);
}

/// Hoạt động gần nhất hiển thị trên thẻ nhóm; `null` khi nhóm chưa có hoạt động.
@freezed
class ActivitySummaryModel with _$ActivitySummaryModel {
  const factory ActivitySummaryModel({
    required String description,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ActivitySummaryModel;

  factory ActivitySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ActivitySummaryModelFromJson(json);
}

@freezed
class GroupListItemModel with _$GroupListItemModel {
  const factory GroupListItemModel({
    required GroupModel group,
    @JsonKey(name: 'caller_membership_id') required String callerMembershipId,
    @JsonKey(name: 'caller_role') required String callerRole,
    @JsonKey(name: 'active_member_count') @Default(0) int activeMemberCount,
    // Backend trả số dư dạng chuỗi để không mất chính xác khi parse số lớn.
    @JsonKey(name: 'caller_net_balance') @Default('0') String callerNetBalance,
    @JsonKey(name: 'pending_bill_count') @Default(0) int pendingBillCount,
    @JsonKey(name: 'last_activity') ActivitySummaryModel? lastActivity,
  }) = _GroupListItemModel;

  factory GroupListItemModel.fromJson(Map<String, dynamic> json) =>
      _$GroupListItemModelFromJson(json);
}

@freezed
class GroupListResponseModel with _$GroupListResponseModel {
  const factory GroupListResponseModel({
    @Default(<GroupListItemModel>[]) List<GroupListItemModel> groups,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _GroupListResponseModel;

  factory GroupListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$GroupListResponseModelFromJson(json);
}

@freezed
class MembershipModel with _$MembershipModel {
  const factory MembershipModel({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
    required String status,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
    @JsonKey(name: 'left_at') DateTime? leftAt,
  }) = _MembershipModel;

  factory MembershipModel.fromJson(Map<String, dynamic> json) => _$MembershipModelFromJson(json);
}

@freezed
class CreateGroupResponseModel with _$CreateGroupResponseModel {
  const factory CreateGroupResponseModel({
    required GroupModel group,
    required MembershipModel membership,
  }) = _CreateGroupResponseModel;

  factory CreateGroupResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupResponseModelFromJson(json);
}

@freezed
class GroupWrapperModel with _$GroupWrapperModel {
  const factory GroupWrapperModel({required GroupModel group}) = _GroupWrapperModel;

  factory GroupWrapperModel.fromJson(Map<String, dynamic> json) =>
      _$GroupWrapperModelFromJson(json);
}

/// Backend cố ý **không** trả số điện thoại thành viên (quyền riêng tư), nên
/// entity phía FE phải chấp nhận `phone` rỗng.
@freezed
class MemberModel with _$MemberModel {
  const factory MemberModel({
    @JsonKey(name: 'membership_id') required String membershipId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    required String role,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _MemberModel;

  factory MemberModel.fromJson(Map<String, dynamic> json) => _$MemberModelFromJson(json);
}

@freezed
class BalanceModel with _$BalanceModel {
  const factory BalanceModel({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'net_balance') @Default('0') String netBalance,
  }) = _BalanceModel;

  factory BalanceModel.fromJson(Map<String, dynamic> json) => _$BalanceModelFromJson(json);
}

@freezed
class GroupDetailResponseModel with _$GroupDetailResponseModel {
  const factory GroupDetailResponseModel({
    required GroupModel group,
    @Default(<MemberModel>[]) List<MemberModel> members,
    @Default(<BalanceModel>[]) List<BalanceModel> balances,
    @JsonKey(name: 'caller_role') required String callerRole,
    // Chỉ Captain mới nhận được hai field batch dưới đây.
    @JsonKey(name: 'active_bill_finalize_batch_id') String? activeBillFinalizeBatchId,
    @JsonKey(name: 'latest_bill_finalize_batch_id') String? latestBillFinalizeBatchId,
  }) = _GroupDetailResponseModel;

  factory GroupDetailResponseModel.fromJson(Map<String, dynamic> json) =>
      _$GroupDetailResponseModelFromJson(json);
}

@freezed
class InviteModel with _$InviteModel {
  const factory InviteModel({
    required String id,
    required String code,
    @JsonKey(name: 'invite_url') required String inviteUrl,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'max_uses') int? maxUses,
    @JsonKey(name: 'use_count') @Default(0) int useCount,
  }) = _InviteModel;

  factory InviteModel.fromJson(Map<String, dynamic> json) => _$InviteModelFromJson(json);
}

@freezed
class InviteWrapperModel with _$InviteWrapperModel {
  const factory InviteWrapperModel({required InviteModel invite}) = _InviteWrapperModel;

  factory InviteWrapperModel.fromJson(Map<String, dynamic> json) =>
      _$InviteWrapperModelFromJson(json);
}

@freezed
class InviteListResponseModel with _$InviteListResponseModel {
  const factory InviteListResponseModel({@Default(<InviteModel>[]) List<InviteModel> invites}) =
      _InviteListResponseModel;

  factory InviteListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$InviteListResponseModelFromJson(json);
}

@freezed
class InvitePreviewModel with _$InvitePreviewModel {
  const factory InvitePreviewModel({
    @JsonKey(name: 'group_name') required String groupName,
    @JsonKey(name: 'active_member_count') @Default(0) int activeMemberCount,
    @JsonKey(name: 'captain_display_name') required String captainDisplayName,
  }) = _InvitePreviewModel;

  factory InvitePreviewModel.fromJson(Map<String, dynamic> json) =>
      _$InvitePreviewModelFromJson(json);
}

@freezed
class InvitePreviewWrapperModel with _$InvitePreviewWrapperModel {
  const factory InvitePreviewWrapperModel({required InvitePreviewModel preview}) =
      _InvitePreviewWrapperModel;

  factory InvitePreviewWrapperModel.fromJson(Map<String, dynamic> json) =>
      _$InvitePreviewWrapperModelFromJson(json);
}

@freezed
class JoinResultModel with _$JoinResultModel {
  const factory JoinResultModel({
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'membership_id') required String membershipId,
    required String role,
    required String status,
    // 'joined' | 'already_member' | 'reactivated'
    required String result,
  }) = _JoinResultModel;

  factory JoinResultModel.fromJson(Map<String, dynamic> json) => _$JoinResultModelFromJson(json);
}

@freezed
class JoinResultWrapperModel with _$JoinResultWrapperModel {
  const factory JoinResultWrapperModel({
    @JsonKey(name: 'join') required JoinResultModel joinResult,
  }) = _JoinResultWrapperModel;

  factory JoinResultWrapperModel.fromJson(Map<String, dynamic> json) =>
      _$JoinResultWrapperModelFromJson(json);
}

@freezed
class CaptainTransferModel with _$CaptainTransferModel {
  const factory CaptainTransferModel({
    @JsonKey(name: 'previous_captain_member_id') required String previousCaptainMemberId,
    @JsonKey(name: 'current_captain_member_id') required String currentCaptainMemberId,
  }) = _CaptainTransferModel;

  factory CaptainTransferModel.fromJson(Map<String, dynamic> json) =>
      _$CaptainTransferModelFromJson(json);
}

@freezed
class CaptainTransferWrapperModel with _$CaptainTransferWrapperModel {
  const factory CaptainTransferWrapperModel({required CaptainTransferModel transfer}) =
      _CaptainTransferWrapperModel;

  factory CaptainTransferWrapperModel.fromJson(Map<String, dynamic> json) =>
      _$CaptainTransferWrapperModelFromJson(json);
}

@freezed
class ActivityActorModel with _$ActivityActorModel {
  const factory ActivityActorModel({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _ActivityActorModel;

  factory ActivityActorModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityActorModelFromJson(json);
}

@freezed
class ActivityModel with _$ActivityModel {
  const factory ActivityModel({
    required String id,
    @JsonKey(name: 'action_type') required String actionType,
    required String description,
    required ActivityActorModel actor,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ActivityModel;

  factory ActivityModel.fromJson(Map<String, dynamic> json) => _$ActivityModelFromJson(json);
}

@freezed
class ActivityListResponseModel with _$ActivityListResponseModel {
  const factory ActivityListResponseModel({
    @Default(<ActivityModel>[]) List<ActivityModel> activities,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _ActivityListResponseModel;

  factory ActivityListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityListResponseModelFromJson(json);
}
