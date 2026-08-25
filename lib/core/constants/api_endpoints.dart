/// Central registry of REST endpoints (relative to [EnvConfig.apiBaseUrl]).
/// Keeping paths here avoids magic strings scattered across datasources.
abstract class ApiEndpoints {
  static const String login = '/auth/sign-in';
  static const String register = '/auth/sign-up';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String me = '/users/me';
  static const String changePassword = '/users/me/password';
  static const String avatar = '/users/me/avatar';

  static const String bills = '/bills';
  static String billById(String id) => '/bills/$id';
  static const String calculateBill = '/bills/calculate';
  static String calculateBillById(String id) => '/bills/$id/calculate';
  static const String scanReceipt = '/bills/scan';
  static const String groups = '/groups';

  static String vietQr(String billId) => '/bills/$billId/vietqr';
}
