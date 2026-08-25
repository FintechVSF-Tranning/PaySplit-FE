import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../di/injection.dart';
import '../domain/repositories/group_repository.dart';
import '../domain/usecases/create_invite_usecase.dart';
import '../domain/usecases/list_invites_usecase.dart';

/// Lấy mã mời đang dùng được của nhóm để hiển thị link/QR.
///
/// `GET /groups` không trả mã mời, nên các sheet mời phải tự tải: đọc danh sách
/// mã còn hiệu lực trước, chỉ khi nhóm chưa có mã nào mới gọi tạo mới. Thứ tự
/// này tránh việc mỗi lần mở sheet lại sinh thêm một mã rác.
Future<Either<Failure, GroupInvite>> resolveGroupInvite(String groupId) async {
  final listed = await getIt<ListInvitesUseCase>().call(groupId);

  final failure = listed.fold<Failure?>((f) => f, (_) => null);
  if (failure != null) return Left(failure);

  final invites = listed.fold<List<GroupInvite>>((_) => const [], (items) => items);
  if (invites.isNotEmpty) return Right(invites.first);

  return getIt<CreateInviteUseCase>().call(CreateInviteParams(groupId: groupId));
}
