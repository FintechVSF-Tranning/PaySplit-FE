import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../di/injection.dart';
import '../../domain/entities/bill_list_page.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../../../app/session/session_scope.dart';

part 'bills_provider.g.dart';

/// Danh sách hóa đơn của một nhóm (`GET /api/v1/bills?group_id=...`).
@riverpod
Future<BillListPage> bills(BillsRef ref, String groupId) async {
  ref.watch(sessionRevisionProvider);
  final result = await getIt<GetBillsUseCase>().call(
    GetBillsParams(groupId: groupId, limit: 50),
  );
  return result.match((failure) => throw failure, (page) => page);
}
