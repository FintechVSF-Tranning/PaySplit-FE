/// Centralized route paths. Referencing these constants instead of raw
/// strings keeps `context.go`/`context.push` calls in sync with the
/// definitions in [AppRouter].
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/';
  static const String bills = '/bills';
}
