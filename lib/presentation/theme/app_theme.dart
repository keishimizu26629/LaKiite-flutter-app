import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFFffa600);
  static const secondaryColor = Color(0xFFa96900);
  static const backgroundColor = Color(0xFFfff5e6);
  static const weekendColor = Color(0xFFcc4d4d); // 赤みがかった色

  static ThemeData get theme => ThemeData(
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
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: primaryColor,
          selectedItemColor: secondaryColor,
          unselectedItemColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: primaryColor,
          unselectedLabelColor: Color(0xFFcc8500),
          indicatorColor: Color(0xFF663d00),
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: primaryColor,
          labelStyle: TextStyle(color: Colors.white),
        ),
      );
}