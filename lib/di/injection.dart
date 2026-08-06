import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Generates registrations for every `@injectable` / `@lazySingleton` /
/// `@module` annotated class found under `lib/`. Run `dart run
/// build_runner build` after adding new injectable classes to refresh
/// `injection.config.dart`.
@InjectableInit()
void configureDependencies() => getIt.init();
