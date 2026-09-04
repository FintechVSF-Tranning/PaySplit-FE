import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/group_models.dart';
import '../models/group_sync_models.dart';

part 'group_remote_datasource.g.dart';

/// Datasource cho 13 endpoint của module `group` (PaySplit-BE).
///
/// Đường dẫn có tham số phải viết literal kèm `{}` vì annotation của retrofit
/// chỉ nhận hằng biên dịch — các helper trong [ApiEndpoints] dùng cho những chỗ
/// gọi Dio trực tiếp, không dùng được ở đây.
@RestApi()
@injectable
abstract class GroupRemoteDataSource {
  @factoryMethod
  factory GroupRemoteDataSource(Dio dio) = _GroupRemoteDataSource;

  @POST(ApiEndpoints.groups)
  Future<ApiResponse<CreateGroupResponseModel>> createGroup(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.groups)
  Future<ApiResponse<GroupListResponseModel>> listGroups({
    @Query('limit') int? limit,
    @Query('cursor') String? cursor,
  });

  @GET('/groups/{id}')
  Future<ApiResponse<GroupDetailResponseModel>> getGroupDetail(@Path('id') String id);

  @PATCH('/groups/{id}')
  Future<ApiResponse<GroupWrapperModel>> renameGroup(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  // 204 No Content: không có body nên không bọc envelope.
  @DELETE('/groups/{id}')
  Future<void> disbandGroup(@Path('id') String id);

  @GET('/groups/{id}/invites')
  Future<ApiResponse<InviteListResponseModel>> listInvites(@Path('id') String id);

  @POST('/groups/{id}/invites')
  Future<ApiResponse<InviteWrapperModel>> createInvite(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  // 204 No Content.
  @DELETE('/groups/{id}/invites/{inviteId}')
  Future<void> revokeInvite(@Path('id') String id, @Path('inviteId') String inviteId);

  @GET('/groups/invites/{code}')
  Future<ApiResponse<InvitePreviewWrapperModel>> previewInvite(@Path('code') String code);

  @POST(ApiEndpoints.joinGroup)
  Future<ApiResponse<JoinResultWrapperModel>> joinGroup(@Body() Map<String, dynamic> body);

  // 204 No Content: dùng chung cho rời nhóm và Captain xóa thành viên.
  @DELETE('/groups/{id}/members/{memberId}')
  Future<void> leaveOrRemoveMember(@Path('id') String id, @Path('memberId') String memberId);

  @PUT('/groups/{id}/members/{memberId}/role')
  Future<ApiResponse<CaptainTransferWrapperModel>> transferRole(
    @Path('id') String id,
    @Path('memberId') String memberId,
    @Body() Map<String, dynamic> body,
  );

  /// Catch-up nguội. `since` bỏ trống hoặc 0 luôn cho ra snapshot.
  @GET('/groups/{id}/sync')
  Future<ApiResponse<GroupSyncResponseModel>> syncGroup(
    @Path('id') String id, {
    @Query('since') int? since,
  });

  @GET('/groups/{id}/activities')
  Future<ApiResponse<ActivityListResponseModel>> listActivities(
    @Path('id') String id, {
    @Query('limit') int? limit,
    @Query('cursor') String? cursor,
  });

  /// Khóa gửi hóa đơn (Spec 0008). Thuộc module `bill` nhưng mount trên
  /// `/groups`, và là một hành động vòng đời nhóm nên đặt cùng chỗ này.
  @POST('/groups/{id}/bills/lock-submissions')
  Future<ApiResponse<GroupBillLockModel>> lockBillSubmissions(
    @Path('id') String id, {
    @Header('Idempotency-Key') required String idempotencyKey,
  });

  /// Mở khóa gửi hóa đơn.
  @POST('/groups/{id}/bills/unlock-submissions')
  Future<ApiResponse<GroupBillLockModel>> unlockBillSubmissions(
    @Path('id') String id,
  );
}
