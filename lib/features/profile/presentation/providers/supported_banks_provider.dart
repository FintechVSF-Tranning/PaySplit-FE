import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/bank_entity.dart';
import '../../domain/usecases/get_supported_banks_usecase.dart';

final supportedBanksProvider = FutureProvider.autoDispose<List<BankEntity>>((
  ref,
) async {
  final result = await getIt<GetSupportedBanksUseCase>()(const NoParams());
  return result.fold<List<BankEntity>>(
    (failure) => throw failure,
    (banks) => banks,
  );
});
