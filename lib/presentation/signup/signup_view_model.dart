import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation_provider.dart';

final signupViewModelProvider =
    StateNotifierProvider<SignupViewModel, AsyncValue<void>>(
  (ref) => SignupViewModel(ref),
);

class SignupViewModel extends StateNotifier<AsyncValue<void>> {
  SignupViewModel(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> signUp(String email, String password, String userId) async {
    state = const AsyncLoading();
    try {
      if (userId.length < 8) {
        throw Exception('ユーザーIDは8文字以上である必要があります');
      }
      await ref.read(authRepositoryProvider).signUp(email, password, userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}