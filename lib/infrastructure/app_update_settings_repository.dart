import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/app_update_settings.dart';
import '../domain/interfaces/i_app_update_settings_repository.dart';

/// Firestore からアプリ更新設定を読み取るリポジトリ。
class AppUpdateSettingsRepository implements IAppUpdateSettingsRepository {
  AppUpdateSettingsRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const settingsCollection = 'settings';
  static const appVersionDocumentId = 'appVersion';

  final FirebaseFirestore _firestore;

  @override
  Stream<AppUpdateSettings?> watchSettings() {
    return _firestore
        .collection(settingsCollection)
        .doc(appVersionDocumentId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return AppUpdateSettings.fromJson(data);
    });
  }
}
