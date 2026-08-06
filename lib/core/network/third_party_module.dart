import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Registers third-party classes that injectable can't construct on its
/// own (no `@injectable` annotation to add, since they live outside this
/// codebase).
@module
abstract class ThirdPartyModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
