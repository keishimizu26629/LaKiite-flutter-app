import 'package:flutter/material.dart';

class DisplayListPalette {
  const DisplayListPalette._();

  static const defaultColorKey = 'blue';

  static const entries = [
    DisplayListPaletteEntry(key: 'red', label: 'レッド', color: Colors.red),
    DisplayListPaletteEntry(key: 'green', label: 'グリーン', color: Colors.green),
    DisplayListPaletteEntry(key: 'teal', label: 'ティール', color: Colors.teal),
    DisplayListPaletteEntry(key: 'cyan', label: 'シアン', color: Colors.cyan),
    DisplayListPaletteEntry(key: 'blue', label: 'ブルー', color: Colors.blue),
    DisplayListPaletteEntry(
      key: 'indigo',
      label: 'インディゴ',
      color: Colors.indigo,
    ),
    DisplayListPaletteEntry(key: 'purple', label: 'パープル', color: Colors.purple),
    DisplayListPaletteEntry(key: 'pink', label: 'ピンク', color: Colors.pink),
  ];

  static Color colorForKey(String colorKey) {
    for (final entry in entries) {
      if (entry.key == colorKey) {
        return entry.color;
      }
    }
    return Colors.blue;
  }
}

class DisplayListPaletteEntry {
  const DisplayListPaletteEntry({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}
