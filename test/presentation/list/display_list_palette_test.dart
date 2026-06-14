import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';

void main() {
  group('DisplayListPalette', () {
    test('uses the first palette entry as the default color', () {
      expect(DisplayListPalette.defaultColorKey,
          DisplayListPalette.entries.first.key);
    });

    test('falls back to the first palette color for unknown keys', () {
      expect(DisplayListPalette.colorForKey('unknown'), Colors.red);
      expect(
        DisplayListPalette.colorForKey('unknown'),
        DisplayListPalette.entries.first.color,
      );
    });
  });
}
