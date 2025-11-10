import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/di/repository_providers.dart';
import 'mock_auth_repository.dart';

class FirebaseTestUtils {
  static ProviderContainer? _container;

  static Future<void> setupFirebaseForTesting() async {
    try {
      await Firebase.initializeApp();
      await _clearFirebaseCache();
      _setupTestProviders();
      debugPrint('Firebase initialized for testing');
    } catch (e) {
      debugPrint('Error initializing Firebase for testing: $e');
      rethrow;
    }
  }

  static Future<void> cleanupFirebaseAfterTesting() async {
    try {
      await _clearFirebaseCache();
      _container?.dispose();
      debugPrint('Firebase cleanup completed');
    } catch (e) {
      debugPrint('Error cleaning up Firebase: $e');
      rethrow;
    }
  }

  // Firebaseのキャッシュをクリア
  static Future<void> _clearFirebaseCache() async {
    try {
      await FirebaseAuth.instance.signOut();
      // 必要に応じて他のキャッシュのクリアを追加
    } catch (e) {
      debugPrint('Error clearing Firebase cache: $e');
    }
  }

  // テスト用のプロバイダーを設定
  static void _setupTestProviders() {
    _container = ProviderContainer(
      overrides: [
        // AuthRepositoryをモックに置き換え
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
  }

  // テスト用のProviderContainerを取得
  static ProviderContainer get container {
    if (_container == null) {
      throw StateError(
          'Provider container not initialized. Call setupFirebaseForTesting() first.');
    }
    return _container!;
  }
}
