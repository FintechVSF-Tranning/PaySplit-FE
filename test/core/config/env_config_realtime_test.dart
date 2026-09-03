import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/config/env_config.dart';

void main() {
  test('realtimeMode defaults to auto and accepts user or legacy', () {
    // covers: AC-23
    expect(EnvConfig.realtimeMode, 'auto');
    EnvConfig.init(
      flavor: Flavor.development,
      apiBaseUrl: 'http://localhost:8080/api/v1',
      appName: 'PaySplit Test',
      realtimeMode: 'user',
    );
    expect(EnvConfig.realtimeMode, 'user');
    EnvConfig.init(
      flavor: Flavor.development,
      apiBaseUrl: 'http://localhost:8080/api/v1',
      appName: 'PaySplit Test',
      realtimeMode: 'legacy',
    );
    expect(EnvConfig.realtimeMode, 'legacy');
  });
}
