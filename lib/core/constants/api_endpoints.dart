/// Central registry of REST endpoints (relative to [EnvConfig.apiBaseUrl]).
/// Keeping paths here avoids magic strings scattered across datasources.
abstract class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  static const String bills = '/bills';
  static String billById(String id) => '/bills/$id';
  static const String scanReceipt = '/bills/scan';

  static String vietQr(String billId) => '/bills/$billId/vietqr';
}
