import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entity/app_update_settings.dart';
import '../../domain/interfaces/i_app_update_settings_repository.dart';
import '../../domain/value/app_version.dart';
import '../../infrastructure/app_update_settings_repository.dart';

/// 強制アップデート機能の有効/無効を切り替えるプロバイダー。
final forceUpdateFeatureEnabledProvider = Provider<bool>((ref) => true);

/// 現在のアプリバージョン情報を提供するプロバイダー。
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// アプリ更新設定リポジトリを提供するプロバイダー。
final appUpdateSettingsRepositoryProvider =
    Provider<IAppUpdateSettingsRepository>(
  (ref) => AppUpdateSettingsRepository(),
);

/// Firestore のアプリ更新設定を監視するプロバイダー。
final appUpdateSettingsStreamProvider = StreamProvider<AppUpdateSettings?>(
  (ref) => ref.watch(appUpdateSettingsRepositoryProvider).watchSettings(),
);

/// 強制アップデートが必要かどうかを返すプロバイダー。
final isForceUpdateRequiredProvider = Provider<bool>((ref) {
  if (!ref.watch(forceUpdateFeatureEnabledProvider)) {
    return false;
  }

  final settings = ref.watch(appUpdateSettingsStreamProvider).asData?.value;
  if (settings == null || !settings.forceUpdate) {
    return false;
  }

  final packageInfo = ref.watch(packageInfoProvider).asData?.value;
  if (packageInfo == null) {
    return false;
  }

  final minRequiredVersion = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => settings.iOSMinRequiredVersion,
    TargetPlatform.android => settings.androidMinRequiredVersion,
    _ => '',
  };

  return AppVersion.isCurrentVersionLessThanMinRequired(
    currentVersion: packageInfo.version,
    minRequiredVersion: minRequiredVersion,
  );
});
