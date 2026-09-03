import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/di/injection.dart';
import 'package:paysplit/features/groups/domain/entities/group_entity.dart';
import 'package:paysplit/features/groups/domain/repositories/group_repository.dart';
import 'package:paysplit/features/groups/domain/usecases/get_group_detail_usecase.dart';
import 'package:paysplit/features/groups/domain/entities/group_member_entity.dart';
import 'package:paysplit/features/groups/domain/usecases/list_groups_usecase.dart';
import 'package:paysplit/features/groups/presentation/providers/groups_provider.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

GroupEntity _group(int index, {int pendingBillCount = 1}) => GroupEntity(
  id: 'g$index',
  name: 'Nhóm $index',
  memberCount: 3,
  myBalance: 0,
  isCaptain: false,
  pendingBillCount: pendingBillCount,
);

/// Ba trang: 20 + 20 + 5, tổng 45 nhóm.
const _page1Cursor = null;
const _page2Cursor = 'cursor-2';
const _page3Cursor = 'cursor-3';

List<GroupEntity> _range(int from, int to, {int pendingBillCount = 1}) => [
  for (var i = from; i < to; i++) _group(i, pendingBillCount: pendingBillCount),
];

void main() {
  late _MockGroupRepository repository;
  late List<String?> requestedCursors;

  /// Nội dung trang đầu mà backend sẽ trả về ở lần gọi kế tiếp.
  late List<GroupEntity> firstPage;

  setUp(() {
    requestedCursors = [];
    firstPage = _range(0, 20);
    repository = _MockGroupRepository();
    when(
      () => repository.listGroups(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((invocation) async {
      final cursor = invocation.namedArguments[#cursor] as String?;
      requestedCursors.add(cursor);
      switch (cursor) {
        case _page1Cursor:
          return Right(GroupPage(items: firstPage, nextCursor: _page2Cursor));
        case _page2Cursor:
          return Right(
            GroupPage(items: _range(20, 40), nextCursor: _page3Cursor),
          );
        case _page3Cursor:
          return Right(GroupPage(items: _range(40, 45)));
        default:
          return const Right(GroupPage(items: []));
      }
    });
    if (getIt.isRegistered<ListGroupsUseCase>()) {
      getIt.unregister<ListGroupsUseCase>();
    }
    getIt.registerSingleton(ListGroupsUseCase(repository));
    if (getIt.isRegistered<GetGroupDetailUseCase>()) {
      getIt.unregister<GetGroupDetailUseCase>();
    }
    getIt.registerSingleton(GetGroupDetailUseCase(repository));
  });

  tearDown(() {
    if (getIt.isRegistered<ListGroupsUseCase>()) {
      getIt.unregister<ListGroupsUseCase>();
    }
    if (getIt.isRegistered<GetGroupDetailUseCase>()) {
      getIt.unregister<GetGroupDetailUseCase>();
    }
  });

  Future<GroupsNotifier> newNotifier() async {
    final notifier = GroupsNotifier();
    addTearDown(notifier.dispose);
    await pumpEventQueue();
    return notifier;
  }

  /// Dựng notifier và bấm "Xem thêm" cho tới hết ba trang.
  Future<GroupsNotifier> scrolledToThirdPage() async {
    final notifier = await newNotifier();
    await notifier.loadMore();
    await notifier.loadMore();
    expect(notifier.state.groups, hasLength(45));
    requestedCursors.clear();
    return notifier;
  }

  test('chỉ trang đầu được tải lại, đúng một request', () async {
    final notifier = await scrolledToThirdPage();

    await notifier.refresh();

    expect(
      requestedCursors,
      [_page1Cursor],
      reason: 'các trang đã cuộn giữ nguyên nội dung lúc gọi backend',
    );
  });

  test('xóa hóa đơn làm số bill mở trên trang đầu cập nhật', () async {
    final notifier = await scrolledToThirdPage();
    // Backend đã trừ pending_bill_count sau khi hóa đơn bị xóa.
    firstPage = _range(0, 20, pendingBillCount: 0);

    await notifier.refresh();

    expect(notifier.state.groups.first.pendingBillCount, 0);
  });

  test('không cắt danh sách về trang đầu', () async {
    final notifier = await scrolledToThirdPage();

    await notifier.refresh();

    expect(
      notifier.state.groups,
      hasLength(45),
      reason: 'danh sách co lại ngay dưới ngón tay người dùng đang cuộn',
    );
    expect(notifier.state.groups.last.id, 'g44');
  });

  test('nhóm leo lên trang đầu không hiện hai lần', () async {
    final notifier = await scrolledToThirdPage();
    // g30 vừa có hoạt động mới nên backend đẩy nó lên đầu trang một.
    firstPage = [_group(30), ..._range(0, 19)];

    await notifier.refresh();

    final ids = notifier.state.groups.map((group) => group.id).toList();
    expect(ids.where((id) => id == 'g30'), hasLength(1));
    expect(ids.first, 'g30');
  });

  test('bấm "Xem thêm" sau khi tải lại vẫn ra trang kế tiếp', () async {
    // Dừng ở trang hai để vẫn còn trang ba chưa tải.
    final notifier = await newNotifier();
    await notifier.loadMore();
    expect(notifier.state.groups, hasLength(40));
    requestedCursors.clear();

    await notifier.refresh();
    requestedCursors.clear();
    await notifier.loadMore();

    expect(
      requestedCursors,
      [_page3Cursor],
      reason: 'cursor phải tiếp tục từ sau phần đuôi, không phải sau trang đầu',
    );
    expect(notifier.state.groups, hasLength(45));
  });

  test('chưa cuộn thì cursor lấy theo trang đầu vừa tải', () async {
    final notifier = await newNotifier();
    expect(notifier.state.groups, hasLength(20));
    requestedCursors.clear();

    await notifier.refresh();
    await notifier.loadMore();

    expect(requestedCursors, [_page1Cursor, _page2Cursor]);
    expect(notifier.state.groups, hasLength(40));
  });

  test(
    'nhóm vừa tham gia đẩy danh sách xuống, không nhóm nào biến mất',
    () async {
      final notifier = await scrolledToThirdPage();
      final before = notifier.state.groups.map((group) => group.id).toSet();
      // Vừa tham gia một nhóm ở thiết bị/luồng khác: backend chèn nó lên đầu và
      // đẩy g19 xuống trang hai, trong khi danh sách tại client chưa kịp biết.
      firstPage = [_group(99), ..._range(0, 19)];

      await notifier.refresh();

      final after = notifier.state.groups.map((group) => group.id).toSet();
      expect(
        before.difference(after),
        isEmpty,
        reason: 'một nhóm đang hiển thị vừa biến mất khỏi danh sách',
      );
      expect(after, contains('g99'));
    },
  );

  group('vá tại chỗ một nhóm', () {
    /// `GET /groups/{id}` trả về nhóm với số bill mở đã giảm.
    void detailReturns(String groupId, {required int pendingBillCount}) {
      when(() => repository.getGroupDetail(groupId)).thenAnswer(
        (_) async => Right(
          GroupDetailResult(
            group: GroupEntity(
              id: groupId,
              name: 'Nhóm $groupId',
              memberCount: 3,
              myBalance: -50000,
              isCaptain: false,
              pendingBillCount: pendingBillCount,
            ),
            members: const <GroupMemberEntity>[],
            balances: const {},
            callerRole: 'member',
          ),
        ),
      );
    }

    test('nhóm ở cuối danh sách cập nhật mà không đổi vị trí', () async {
      final notifier = await scrolledToThirdPage();
      final positionBefore = notifier.state.groups.indexWhere(
        (group) => group.id == 'g33',
      );
      detailReturns('g33', pendingBillCount: 0);

      await notifier.patchGroup('g33');

      final patched = notifier.state.groups.firstWhere((g) => g.id == 'g33');
      expect(patched.pendingBillCount, 0, reason: 'số bill mở không cập nhật');
      expect(patched.myBalance, -50000);
      expect(
        notifier.state.groups.indexWhere((group) => group.id == 'g33'),
        positionBefore,
        reason: 'dòng nhảy chỗ ngay dưới ngón tay người dùng',
      );
      expect(notifier.state.groups, hasLength(45));
    });

    test('không gọi backend cho nhóm ngoài danh sách đang tải', () async {
      final notifier = await scrolledToThirdPage();

      await notifier.patchGroup('g999');

      verifyNever(() => repository.getGroupDetail('g999'));
    });

    test('vá hỏng thì báo lỗi mà không dựng cờ lỗi toàn màn hình', () async {
      final notifier = await scrolledToThirdPage();
      when(
        () => repository.getGroupDetail('g33'),
      ).thenAnswer((_) async => const Left(NetworkFailure('mất mạng')));

      await expectLater(
        notifier.patchGroup('g33', rethrowFailure: true),
        throwsA(isA<NetworkFailure>()),
      );
      expect(
        notifier.state.failure,
        isNull,
        reason: 'một thẻ nhóm hỏng không nên làm cả màn hình hiện lỗi',
      );
      expect(notifier.state.groups, hasLength(45));
    });
  });

  group('khi tải lại hỏng', () {
    /// `cursor` bỏ trống nghĩa là chỉ khớp lời gọi trang đầu (cursor null).
    void failFirstPage() {
      when(
        () => repository.listGroups(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure('mất mạng')));
    }

    test('giữ nguyên danh sách đang hiển thị', () async {
      final notifier = await scrolledToThirdPage();
      failFirstPage();

      await notifier.refresh();

      expect(notifier.state.groups, hasLength(45));
      expect(notifier.state.failure, isA<NetworkFailure>());
      expect(notifier.state.isLoading, isFalse);
    });

    test('báo lỗi cho tầng realtime để invalidation được thử lại', () async {
      final notifier = await scrolledToThirdPage();
      failFirstPage();

      await expectLater(
        notifier.refresh(rethrowFailure: true),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
