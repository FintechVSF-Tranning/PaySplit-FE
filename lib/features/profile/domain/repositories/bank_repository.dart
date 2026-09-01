import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bank_entity.dart';

abstract class BankRepository {
  Future<Either<Failure, List<BankEntity>>> getSupportedBanks();
}
