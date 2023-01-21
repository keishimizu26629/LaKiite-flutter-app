import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarakite/infrastructure/authRepository.dart';
import '../presentation_provider.dart';
import '../../domain/interfaces/i_auth_repository.dart';
import '../signup/signup.dart';

final loginViewModelProvider = Provider<LoginViewModel>((ref) {
  return LoginViewModel(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class LoginViewModel {
  final ProviderRef ref;
  final IauthRepository authRepository;

  LoginViewModel({required this.ref, required this.authRepository});

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

  void toSignUp({required BuildContext context}) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignUp_page()),
        (_) => false);
  }
}
