import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation_provider.dart';

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, AsyncValue<void>>(
  (ref) => LoginViewModel(ref),
);

class LoginViewModel extends StateNotifier<AsyncValue<void>> {
  LoginViewModel(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signIn(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}