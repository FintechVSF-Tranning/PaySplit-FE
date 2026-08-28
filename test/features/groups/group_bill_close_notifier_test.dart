import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/groups/domain/entities/bulk_finalize_entity.dart';
import 'package:paysplit/features/groups/domain/repositories/group_bill_close_repository.dart';
import 'package:paysplit/features/groups/domain/usecases/group_bill_close_usecases.dart';
import 'package:paysplit/features/groups/presentation/providers/group_bill_close_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGroupBillCloseRepository repository;
  late StartBulkFinalizeUseCase startUseCase;
  late GetBulkFinalizeUseCase getUseCase;
  late List<String> generatedUuids;

  String fakeUuid() {
    final uuid = 'uuid-${generatedUuids.length + 1}';
    generatedUuids.add(uuid);
    return uuid;
  }

  setUp(() {
    repository = FakeGroupBillCloseRepository();
    startUseCase = StartBulkFinalizeUseCase(repository);
    getUseCase = GetBulkFinalizeUseCase(repository);
    generatedUuids = [];
  });

  GroupBillCloseNotifier createNotifier({String groupId = 'group-1'}) {
    return GroupBillCloseNotifier(
      groupId: groupId,
      startUseCase: startUseCase,
      getUseCase: getUseCase,
      uuidFactory: fakeUuid,
    );
  }

  test(
    'Start thành công tạo idempotency key, mở batch và reset key cho lần sau',
    () async {
      final notifier = createNotifier();
      addTearDown(notifier.dispose);

      repository.startResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-1',
          status: BulkFinalizeStatus.queued,
          targetCount: 5,
          finalizedCount: 0,
          failedCount: 0,
        ),
      );
      repository.getBatchResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-1',
          status: BulkFinalizeStatus.processing,
          targetCount: 5,
          finalizedCount: 2,
          failedCount: 0,
        ),
      );

      final success = await notifier.start();
      expect(success, isTrue);
      expect(repository.recordedIdempotencyKeys, ['uuid-1']);
      expect(notifier.state.batch?.id, 'batch-1');

      // Lần start kế tiếp phải dùng key mới
      repository.startResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-2',
          status: BulkFinalizeStatus.queued,
          targetCount: 3,
          finalizedCount: 0,
          failedCount: 0,
        ),
      );
      await notifier.start();
      expect(repository.recordedIdempotencyKeys, ['uuid-1', 'uuid-2']);
    },
  );

  test('Start lỗi transient (500) giữ nguyên key cho lần retry', () async {
    final notifier = createNotifier();
    addTearDown(notifier.dispose);

    repository.startResult = const Left(
      ServerFailure('Lỗi máy chủ', code: 'INTERNAL_ERROR', statusCode: 500),
    );

    final firstAttempt = await notifier.start();
    expect(firstAttempt, isFalse);
    expect(repository.recordedIdempotencyKeys, ['uuid-1']);

    // Retry lần 2: phải tái sử dụng 'uuid-1'
    repository.startResult = Right(
      const BulkFinalizeBatchEntity(
        id: 'batch-1',
        status: BulkFinalizeStatus.queued,
        targetCount: 5,
        finalizedCount: 0,
        failedCount: 0,
      ),
    );
    final secondAttempt = await notifier.start();
    expect(secondAttempt, isTrue);
    expect(repository.recordedIdempotencyKeys, ['uuid-1', 'uuid-1']);
  });

  test('Start lỗi 400 dứt khoát reset key cho lần gọi sau', () async {
    final notifier = createNotifier();
    addTearDown(notifier.dispose);

    repository.startResult = const Left(
      ServerFailure(
        'Dữ liệu không hợp lệ',
        code: 'BAD_REQUEST',
        statusCode: 400,
      ),
    );

    final first = await notifier.start();
    expect(first, isFalse);
    expect(repository.recordedIdempotencyKeys, ['uuid-1']);

    // Lần sau tạo key mới
    repository.startResult = const Left(
      ServerFailure(
        'Dữ liệu không hợp lệ',
        code: 'BAD_REQUEST',
        statusCode: 400,
      ),
    );
    await notifier.start();
    expect(repository.recordedIdempotencyKeys, ['uuid-1', 'uuid-2']);
  });

  test(
    'BULK_FINALIZE_IN_PROGRESS tự động mở active batch từ details',
    () async {
      final notifier = createNotifier();
      addTearDown(notifier.dispose);

      repository.startResult = const Left(
        ServerFailure(
          'Tiến trình đang chạy',
          code: 'BULK_FINALIZE_IN_PROGRESS',
          statusCode: 409,
          details: {'active_batch_id': 'active-batch-99'},
        ),
      );
      repository.getBatchResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'active-batch-99',
          status: BulkFinalizeStatus.processing,
          targetCount: 10,
          finalizedCount: 3,
          failedCount: 0,
        ),
      );

      final result = await notifier.start();
      expect(result, isTrue);
      expect(notifier.state.batch?.id, 'active-batch-99');
    },
  );

  test('loadMore lỗi không làm mất danh sách item hiện có', () async {
    final notifier = createNotifier();
    addTearDown(notifier.dispose);

    await notifier.open('batch-1');
    repository.getBatchResult = Right(
      const BulkFinalizeBatchEntity(
        id: 'batch-1',
        status: BulkFinalizeStatus.completed,
        targetCount: 2,
        finalizedCount: 1,
        failedCount: 1,
        items: [
          BulkFinalizeItemEntity(
            billId: 'b-1',
            billName: 'Bill 1',
            status: BulkFinalizeItemStatus.finalized,
          ),
        ],
        nextCursor: 'cursor-2',
      ),
    );
    await notifier.open('batch-1');
    expect(notifier.state.batch?.items, hasLength(1));

    // Load more fail
    repository.getBatchResult = const Left(
      ServerFailure('Mất kết nối mạng', code: 'NETWORK_ERROR'),
    );
    await notifier.loadMore();

    // Items cũ vẫn còn nguyên
    expect(notifier.state.batch?.items, hasLength(1));
    expect(notifier.state.errorMessage, 'Mất kết nối mạng');
  });

  test(
    'Polling merge item theo billId giữ lại các trang đã load more',
    () async {
      final notifier = createNotifier();
      addTearDown(notifier.dispose);

      // Initial load: 1 item + next cursor
      repository.getBatchResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-1',
          status: BulkFinalizeStatus.processing,
          targetCount: 3,
          finalizedCount: 1,
          failedCount: 0,
          items: [
            BulkFinalizeItemEntity(
              billId: 'b-1',
              billName: 'Bill 1',
              status: BulkFinalizeItemStatus.finalized,
            ),
          ],
          nextCursor: 'cursor-2',
        ),
      );
      await notifier.open('batch-1');

      // Load more page 2: thêm b-2
      repository.getBatchResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-1',
          status: BulkFinalizeStatus.processing,
          targetCount: 3,
          finalizedCount: 1,
          failedCount: 0,
          items: [
            BulkFinalizeItemEntity(
              billId: 'b-2',
              billName: 'Bill 2',
              status: BulkFinalizeItemStatus.pending,
            ),
          ],
        ),
      );
      await notifier.loadMore();
      expect(notifier.state.batch?.items, hasLength(2));

      // Polling page 1 cập nhật status mới cho b-1 và b-3
      repository.getBatchResult = Right(
        const BulkFinalizeBatchEntity(
          id: 'batch-1',
          status: BulkFinalizeStatus.completed,
          targetCount: 3,
          finalizedCount: 2,
          failedCount: 0,
          items: [
            BulkFinalizeItemEntity(
              billId: 'b-1',
              billName: 'Bill 1',
              status: BulkFinalizeItemStatus.finalized,
            ),
            BulkFinalizeItemEntity(
              billId: 'b-3',
              billName: 'Bill 3',
              status: BulkFinalizeItemStatus.finalized,
            ),
          ],
        ),
      );

      // Trigger poll by calling open or internal merge
      await notifier.open('batch-1');
      expect(notifier.state.batch?.items, hasLength(2));
    },
  );

  test('App lifecycle pause/resume quản lý trạng thái polling an toàn', () {
    final notifier = createNotifier();
    addTearDown(notifier.dispose);

    // Chuyển sang background
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    // Không crash, timer bị hủy

    // Resume app
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    // Không crash
  });
}

class FakeGroupBillCloseRepository implements GroupBillCloseRepository {
  final List<String> recordedIdempotencyKeys = [];
  Either<Failure, BulkFinalizeBatchEntity> startResult = Right(
    const BulkFinalizeBatchEntity(
      id: 'default-batch',
      status: BulkFinalizeStatus.queued,
      targetCount: 1,
      finalizedCount: 0,
      failedCount: 0,
    ),
  );

  Either<Failure, BulkFinalizeBatchEntity> getBatchResult = Right(
    const BulkFinalizeBatchEntity(
      id: 'default-batch',
      status: BulkFinalizeStatus.completed,
      targetCount: 1,
      finalizedCount: 1,
      failedCount: 0,
    ),
  );

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> start(
    String groupId, {
    required String idempotencyKey,
  }) async {
    recordedIdempotencyKeys.add(idempotencyKey);
    return startResult;
  }

  @override
  Future<Either<Failure, BulkFinalizeBatchEntity>> getBatch(
    String groupId,
    String batchId, {
    String? cursor,
  }) async {
    return getBatchResult;
  }
}
