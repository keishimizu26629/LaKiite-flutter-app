import '../entity/app_update_settings.dart';

/// アプリ更新設定のリポジトリ。
abstract class IAppUpdateSettingsRepository {
  Stream<AppUpdateSettings?> watchSettings();
}
