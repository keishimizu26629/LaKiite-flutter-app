import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final howToUsePromptPreferencesProvider = Provider<HowToUsePromptPreferences>(
  (ref) => const HowToUsePromptPreferences(),
);

class HowToUsePromptPreferences {
  const HowToUsePromptPreferences();

  static const _hasSeenPromptKey = 'has_seen_how_to_use_prompt';

  Future<bool> shouldShowPrompt() async {
    final preferences = await SharedPreferences.getInstance();
    return !(preferences.getBool(_hasSeenPromptKey) ?? false);
  }

  Future<void> markPromptSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hasSeenPromptKey, true);
  }
}
