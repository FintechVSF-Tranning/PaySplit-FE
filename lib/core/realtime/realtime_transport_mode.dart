import '../config/env_config.dart';

/// Chế độ vận chuyển realtime đang **thực sự** dùng.
///
/// `EnvConfig.realtimeMode` chỉ nói ý định lúc khởi động. Ở chế độ `auto`, nếu
/// server trả 404/501 thì owner rơi về đường legacy — và mọi nơi đang chờ sự
/// kiện phải biết điều đó. Đọc riêng biến môi trường sẽ khiến chúng chờ trên một
/// bus đã chết suốt cả timeout.
class RealtimeTransportMode {
  static final RealtimeTransportMode instance = RealtimeTransportMode();

  bool _legacyFallback = false;

  /// Owner cập nhật mỗi lần trạng thái đường lui thay đổi.
  void setLegacyFallback(bool value) => _legacyFallback = value;

  bool get useLegacy {
    if (EnvConfig.realtimeMode == 'legacy') return true;
    if (EnvConfig.realtimeMode == 'user') return false;
    return _legacyFallback;
  }
}
