import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/session/session_scope.dart';
import 'package:paysplit/features/groups/domain/entities/group_entity.dart';
import 'package:paysplit/features/groups/presentation/providers/group_detail_provider.dart';

/// Cầu nối để test lấy được một [Ref] thật, giống cách AuthController gọi
/// [beginNewSession] sau khi đăng nhập.
final _beginSessionProbe = Provider<void Function()>(
  (ref) => () => beginNewSession(ref),
);

void main() {
  const group = GroupEntity(
    id: 'group-1',
    name: 'Nhóm cũ',
    memberCount: 3,
    myBalance: 0,
    inviteCode: 'ABC123',
    isCaptain: true,
    lastActivity: '',
  );
  const key = GroupDetailKey(group);

  test('đăng nhập tài khoản khác dựng lại provider, không giữ dữ liệu cũ', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(groupDetailProvider(key).notifier).renameGroup('Dữ liệu acc cũ');
    expect(container.read(groupDetailProvider(key)).group.name, 'Dữ liệu acc cũ');

    container.read(_beginSessionProbe)();

    expect(
      container.read(groupDetailProvider(key)).group.name,
      'Nhóm cũ',
      reason: 'provider phải được dựng lại từ đầu khi bắt đầu phiên mới',
    );
  });

  test('provider chưa từng được dùng thì không bị dựng lên khi đổi phiên', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Không đọc groupDetailProvider trước: đổi phiên không được phép đánh thức
    // các provider đang ngủ (sẽ bắn request thừa ngay lúc chuyển tài khoản).
    container.read(_beginSessionProbe)();

    expect(container.read(sessionRevisionProvider), 1);
  });
}
