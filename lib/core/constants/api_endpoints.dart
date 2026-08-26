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

  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  static String vietQr(String billId) => '/bills/$billId/vietqr';

  // --- Groups (module `group`) ---
  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';
  static String groupInvites(String id) => '/groups/$id/invites';
  static String groupInviteById(String id, String inviteId) =>
      '/groups/$id/invites/$inviteId';
  static String invitePreview(String code) => '/groups/invites/$code';
  static const String joinGroup = '/groups/join';
  static String groupMember(String id, String memberId) =>
      '/groups/$id/members/$memberId';
  static String groupMemberRole(String id, String memberId) =>
      '/groups/$id/members/$memberId/role';
  static String groupActivities(String id) => '/groups/$id/activities';

  /// Catch-up nguội: trả delta hoặc snapshot tùy khoảng cách giữa `since` và
  /// version hiện tại của nhóm.
  static String groupSync(String id) => '/groups/$id/sync';

  /// Kênh nóng SSE (`text/event-stream`), không bọc envelope.
  static String groupEvents(String id) => '/groups/$id/events';

  // --- Settlement (tab Công nợ, mount trên /groups) ---
  static String groupDebts(String groupId) => '/groups/$groupId/debts';
  static String groupExpensesMe(String groupId) =>
      '/groups/$groupId/expenses/me';
  static String remindDebt(String groupId, String debtId) =>
      '/groups/$groupId/debts/$debtId/remind';
  static String groupPaymentQr(String groupId) =>
      '/groups/$groupId/payments/qr';
  static String groupPayment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId';
  static String groupPaymentProof(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/proof';
  static String confirmGroupPayment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/confirm';
  static String rejectGroupPayment(String groupId, String paymentId) =>
      '/groups/$groupId/payments/$paymentId/reject';
}
