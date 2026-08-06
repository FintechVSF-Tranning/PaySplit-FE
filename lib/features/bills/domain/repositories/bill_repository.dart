import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> getBills();
}
