import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

@injectable
class GetBillsUseCase implements UseCase<List<BillEntity>, NoParams> {
  GetBillsUseCase(this._repository);

  final BillRepository _repository;

  @override
  Future<Either<Failure, List<BillEntity>>> call(NoParams params) {
    return _repository.getBills();
  }
}
