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
  static const String scanReceipt = '/bills/scan';

  static String vietQr(String billId) => '/bills/$billId/vietqr';

  static const String groups = '/groups';
  static String groupDebts(String groupId) => '/groups/$groupId/debts';
  static String remindDebt(String groupId, String debtId) =>
      '/groups/$groupId/debts/$debtId/remind';
  static String paymentQr(String groupId) => '/groups/$groupId/payments/qr';
  static String payment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId';
  static String paymentProof(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/proof';
  static String confirmPayment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/confirm';
  static String rejectPayment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/reject';
}
