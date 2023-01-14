import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarakite/infrastructure/authRepository.dart';
import '../../domain/interfaces/i_auth_repository.dart';

final myPageViewModelProvider = Provider<MyPageViewModel>((ref) {
  return MyPageViewModel(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class MyPageViewModel {
  final IauthRepository _authRepository;

  MyPageViewModel({required ref, required authRepository})
      : _authRepository = authRepository;

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
