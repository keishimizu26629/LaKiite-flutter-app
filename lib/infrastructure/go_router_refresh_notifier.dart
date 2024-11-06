import 'package:flutter/material.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}