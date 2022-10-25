import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarakite/infrastructure/authRepository.dart';
import '../presentation_provider.dart';
import '../../domain/interfaces/i_auth_repository.dart';

final signInViewModelProvider = Provider<SignInViewModel>((ref) {
  return SignInViewModel(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class SignInViewModel {
  final ProviderRef ref;
  final IauthRepository authRepository;

  SignInViewModel({required this.ref, required this.authRepository});

  TextEditingController get emailAddressController =>
      ref.read(emailAddressControllerStateProvider.state).state;

  TextEditingController get passwordController =>
      ref.read(passwordControllerStateProvider.state).state;

  Future<void> login(context) async {
    if (emailAddressController.text.isEmpty) {
      throw 'メールアドレスを入力してください';
    }
    if (passwordController.text.isEmpty) {
      throw 'パスワードを入力してください';
    }
    await authRepository.login(
      email: emailAddressController.text,
      password: passwordController.text,
      context: context,
    );
    emailAddressController.text = '';
    passwordController.text = '';

  }
}
