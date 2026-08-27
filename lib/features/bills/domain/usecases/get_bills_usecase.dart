import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bill_list_page.dart';
import '../repositories/bill_repository.dart';

class GetBillsParams extends Equatable {
  const GetBillsParams({
    required this.groupId,
    required this.limit,
    this.cursor,
    this.statuses = const [],
  });

  final String groupId;
  final int limit;
  final String? cursor;

  /// Lọc theo trạng thái backend (`draft`/`reviewed`/`finalized`/`voided`).
  /// Rỗng = tất cả.
  final List<String> statuses;

  @override
  List<Object?> get props => [groupId, limit, cursor, statuses];
}

@injectable
class GetBillsUseCase implements UseCase<BillListPage, GetBillsParams> {
  GetBillsUseCase(this._repository);

  final BillRepository _repository;

  @override
  Future<Either<Failure, BillListPage>> call(GetBillsParams params) {
    return _repository.getBills(
      groupId: params.groupId,
      limit: params.limit,
      cursor: params.cursor,
      statuses: params.statuses,
    );
  }
}
