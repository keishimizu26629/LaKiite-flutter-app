import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarakite/infrastructure/authRepository.dart';
import '../presentation_provider.dart';
import '../../domain/interfaces/i_auth_repository.dart';

final myPageViewModelProvider = Provider<MyPageViewModel>((ref) {
  return MyPageViewModel(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class MyPageViewModel {
  final ProviderRef _ref;
  final IauthRepository _authRepository;

  MyPageViewModel({required ref, required authRepository})
      : _ref = ref,
        _authRepository = authRepository;

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {}
  }

  Future<void> test(auth) async {
    await auth.currentUser!.reload();
    debugPrint(auth.currentUser.emailVerified.toString());
  }
}
