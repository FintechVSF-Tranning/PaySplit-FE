/// Bộ định dạng thời gian đếm ngược và thời gian hồi (cooldown).
class TimeFormatter {
  const TimeFormatter._();

  /// Định dạng thời gian hồi ngắn gọn (ví dụ: '22h', '1p', '45s').
  ///
  /// Phù hợp hiển thị gọn gàng trên nhãn button hoặc badge.
  static String formatRemainingCooldown(int totalSeconds) {
    if (totalSeconds <= 0) return '';
    final duration = Duration(seconds: totalSeconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}p';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Định dạng thời gian hồi chi tiết, tự nhiên (ví dụ: '22 giờ', '1 phút', '45 giây').
  ///
  /// Phù hợp hiển thị trong thông báo lỗi hoặc SnackBar cảnh báo.
  static String formatRemainingCooldownDetailed(int totalSeconds) {
    if (totalSeconds <= 0) return 'ngay bây giờ';
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      if (minutes > 0) return '$hours giờ $minutes phút';
      return '$hours giờ';
    } else if (minutes > 0) {
      if (secs > 0) return '$minutes phút $secs giây';
      return '$minutes phút';
    } else {
      return '$secs giây';
    }
  }
}
