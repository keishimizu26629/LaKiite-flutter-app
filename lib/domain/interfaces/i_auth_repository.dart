abstract class IauthRepository {
  Future<void> login({
    required String email,
    required String password,
    required context,
  });
  Future<void> signUp({required String email, required String password});
  String? getUid();
}
