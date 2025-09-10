import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth/auth_notifier.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final goRouterRefreshProvider = Provider((ref) {
  return GoRouterRefreshNotifier(ref);
});
