import 'app_config.dart';

String hostingBaseUrl() {
  try {
    if (AppConfig.instance.isProduction) {
      return 'https://lakiite-flutter-app-prod.web.app';
    }
  } catch (_) {
    return 'https://lakiite-flutter-app-dev.web.app';
  }

  return 'https://lakiite-flutter-app-dev.web.app';
}
