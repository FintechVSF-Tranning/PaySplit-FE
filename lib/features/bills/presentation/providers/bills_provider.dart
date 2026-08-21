import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/get_bills_usecase.dart';

part 'bills_provider.g.dart';

@riverpod
Future<List<BillEntity>> bills(Ref ref) async {
  final result = await getIt<GetBillsUseCase>().call(const NoParams());
  return result.match((failure) => throw failure, (bills) => bills);
}
