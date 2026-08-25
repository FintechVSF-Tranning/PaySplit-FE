abstract class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String bills = '/bills';
  static const String scanBill = '/scan-bill';
  static const String billDetail = '/bill-detail';
  static const String groups = '/groups';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String bankSettings = '/bank-settings';
  static const String changePassword = '/change-password';

  /// Màn hình chi tiết hóa đơn (con của [bills]).
  static String billDetailRoute(String billId) => '$bills/$billId';

  /// Màn hình chi tiết một nhóm (con của [groups]).
  static String groupDetail(String groupId) => '$groups/$groupId';

  /// Màn hình thêm thành viên của một nhóm cụ thể (con của [groups]).
  static String addMembers(String groupId) => '$groups/$groupId/add-members';
}
