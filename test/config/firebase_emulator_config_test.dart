import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/config/firebase_emulator_config.dart';

void main() {
  group('FirebaseEmulatorConfig', () {
    test('明示されたホストを優先する', () {
      final config = FirebaseEmulatorConfig.resolve(
        enabled: true,
        hostOverride: '192.168.0.10',
        isAndroid: true,
      );

      expect(config.enabled, isTrue);
      expect(config.host, '192.168.0.10');
      expect(config.authPort, 9099);
      expect(config.firestorePort, 8080);
      expect(config.storagePort, 9199);
    });

    test('Androidでは10.0.2.2を使う', () {
      final config = FirebaseEmulatorConfig.resolve(
        enabled: true,
        hostOverride: '',
        isAndroid: true,
      );

      expect(config.host, '10.0.2.2');
    });

    test('Android以外ではlocalhostを使う', () {
      final config = FirebaseEmulatorConfig.resolve(
        enabled: true,
        hostOverride: '',
        isAndroid: false,
      );

      expect(config.host, 'localhost');
    });
  });
}
