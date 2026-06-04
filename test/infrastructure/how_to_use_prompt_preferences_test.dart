import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/how_to_use_prompt_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('使い方案内を未表示の場合は表示対象になる', () async {
    SharedPreferences.setMockInitialValues({});

    const preferences = HowToUsePromptPreferences();

    expect(await preferences.shouldShowPrompt(), isTrue);
  });

  test('使い方案内を表示済みにすると次回以降は表示対象外になる', () async {
    SharedPreferences.setMockInitialValues({});

    const preferences = HowToUsePromptPreferences();

    await preferences.markPromptSeen();

    expect(await preferences.shouldShowPrompt(), isFalse);
  });
}
