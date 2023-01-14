
abstract class IauthRepository {
  get authStateChange => null;

  Future<void> login({
    required String email,
    required String password,
    required context,
  });
  Future<void> signUp({required String email, required String password});
  Future<void> logout();
  String? getUid();
}
