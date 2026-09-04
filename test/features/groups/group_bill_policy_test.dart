import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/groups/data/models/group_mapper.dart';
import 'package:paysplit/features/groups/data/models/group_models.dart';
import 'package:paysplit/features/groups/domain/entities/group_entity.dart';
import 'package:paysplit/features/groups/domain/repositories/group_repository.dart';
import 'package:paysplit/features/groups/domain/usecases/unlock_bill_submissions_usecase.dart';

void main() {
  test('AC 3 khóa nhận bill không đóng vòng đời nhóm', () {
    final model = GroupModel(
      id: 'group-1',
      name: 'Đi Đà Lạt',
      currency: 'VND',
      createdAt: DateTime.utc(2026, 8),
      billSubmissionLocked: true,
      billSubmissionLockedAt: DateTime.utc(2026, 8, 24),
    );

    final group = model.toEntity(isCaptain: true);

    expect(group.status, GroupStatus.active);
    expect(group.billSubmissionLocked, isTrue);
    expect(group.isClosed, isTrue);
    expect(group.closedAtText, '24/08/2026');
  });

  test('nhóm chưa khóa vẫn nhận bill mới', () {
    final group = GroupModel(
      id: 'group-2',
      name: 'Nhóm trọ',
      currency: 'VND',
      createdAt: DateTime.utc(2026, 8),
    ).toEntity();

    expect(group.billSubmissionLocked, isFalse);
    expect(group.isClosed, isFalse);
  });

  test('UnlockBillSubmissionsUseCase gọi repository đúng groupId', () async {
    final mockRepo = _MockGroupRepository();
    final useCase = UnlockBillSubmissionsUseCase(mockRepo);

    final result = await useCase('group-123');

    expect(result.isRight(), isTrue);
    expect(mockRepo.unlockedGroupId, 'group-123');
  });
}

class _MockGroupRepository extends MockGroupRepositoryBase {
  String? unlockedGroupId;

  @override
  Future<Either<Failure, Unit>> unlockBillSubmissions(String groupId) async {
    unlockedGroupId = groupId;
    return const Right(unit);
  }
}

abstract class MockGroupRepositoryBase implements GroupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
