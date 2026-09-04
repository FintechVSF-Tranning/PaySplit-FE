import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bank_entity.dart';
import '../repositories/bank_repository.dart';

@injectable
class GetSupportedBanksUseCase implements UseCase<List<BankEntity>, NoParams> {
  const GetSupportedBanksUseCase(this._repository);

  final BankRepository _repository;

  @override
  Future<Either<Failure, List<BankEntity>>> call(NoParams params) =>
      _repository.getSupportedBanks();
}
