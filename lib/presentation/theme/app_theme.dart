import 'package:flutter/material.dart';

class AppTheme {
  // メインカラー
  static const primaryColor = Color(0xFFffa600);
  static const secondaryColor = Color(0xFFa96900);
  static const backgroundColor = Color(0xFFF8F9FA);
  static const weekendColor = Color(0xFFcc4d4d);

  // 追加カラー
  static const surfaceColor = Colors.white;
  static const onSurfaceColor = Colors.black87;
  static const dividerColor = Color(0xFFE4E6E8);
  static const disabledColor = Colors.grey;

  // ユーザーアイコン用カラー
  static const userIconBackgroundColor =
      Color(0xFFfff5e6); // primaryColor[50]と同じ
  static const userIconColor = Color(0xFFffc74d); // primaryColor[300]と同じ

  static ThemeData get theme => ThemeData(
        useMaterial3: false,
        primarySwatch: MaterialColor(
          primaryColor.value,
          const <int, Color>{
            50: Color(0xFFfff5e6),
            100: Color(0xFFffe6b3),
            200: Color(0xFFffd680),
            300: Color(0xFFffc74d),
            400: Color(0xFFffb71a),
            500: primaryColor,
            600: Color(0xFFcc8500),
            700: secondaryColor,
            800: Color(0xFF805000),
            900: Color(0xFF663d00),
          },
        ),
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: backgroundColor,
          onSurface: onSurfaceColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          elevation: 1,
          iconTheme: IconThemeData(color: surfaceColor),
          titleTextStyle: TextStyle(
            color: surfaceColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          toolbarHeight: 60,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.black54,
          selectedIconTheme: IconThemeData(color: primaryColor),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          elevation: 2,
          highlightElevation: 4,
        ),
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          color: surfaceColor,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: primaryColor,
          labelStyle: TextStyle(color: surfaceColor),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: surfaceColor,
            backgroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(primaryColor),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryColor,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return disabledColor;
            }
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return disabledColor;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return disabledColor;
            }
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return disabledColor;
          }),
          trackColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return disabledColor.withOpacity(0.3);
            }
            if (states.contains(WidgetState.selected)) {
              return primaryColor.withOpacity(0.5);
            }
            return disabledColor.withOpacity(0.3);
          }),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        dividerTheme: const DividerThemeData(
          space: 16,
          thickness: 1,
          color: dividerColor,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: surfaceColor,
          iconColor: primaryColor,
          textColor: onSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: onSurfaceColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: onSurfaceColor,
          ),
        ),
      );
}
