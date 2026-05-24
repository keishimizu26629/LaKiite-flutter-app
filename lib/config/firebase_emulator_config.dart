import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Emulator Suite への接続設定を表します。
class FirebaseEmulatorConfig {
  const FirebaseEmulatorConfig({
    required this.enabled,
    required this.host,
    this.authPort = 9099,
    this.firestorePort = 8080,
    this.storagePort = 9199,
  });

  /// dart-define と実行プラットフォームから接続設定を解決します。
  factory FirebaseEmulatorConfig.fromEnvironment() {
    const enabled = bool.fromEnvironment(
      'USE_FIREBASE_EMULATOR',
      defaultValue: false,
    );
    const hostOverride = String.fromEnvironment('FIREBASE_EMULATOR_HOST');

    return FirebaseEmulatorConfig.resolve(
      enabled: enabled,
      hostOverride: hostOverride,
      isAndroid: !kIsWeb && Platform.isAndroid,
    );
  }

  /// テストしやすい純粋関数として接続設定を解決します。
  factory FirebaseEmulatorConfig.resolve({
    required bool enabled,
    required String hostOverride,
    required bool isAndroid,
  }) {
    final host = hostOverride.isNotEmpty
        ? hostOverride
        : isAndroid
            ? '10.0.2.2'
            : 'localhost';

    return FirebaseEmulatorConfig(enabled: enabled, host: host);
  }

  /// Firebase Emulator Suite に接続するかどうか。
  final bool enabled;

  /// Emulator のホスト名。
  final String host;

  /// Firebase Auth emulator のポート番号。
  final int authPort;

  /// Cloud Firestore emulator のポート番号。
  final int firestorePort;

  /// Firebase Storage emulator のポート番号。
  final int storagePort;
}

/// Firebase SDK の接続先を Emulator Suite に切り替えます。
Future<void> connectFirebaseEmulatorsIfNeeded() async {
  final config = FirebaseEmulatorConfig.fromEnvironment();
  if (!config.enabled) {
    return;
  }

  FirebaseFirestore.instance.useFirestoreEmulator(
    config.host,
    config.firestorePort,
  );
  await FirebaseAuth.instance.useAuthEmulator(config.host, config.authPort);
  await FirebaseStorage.instance.useStorageEmulator(
    config.host,
    config.storagePort,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
