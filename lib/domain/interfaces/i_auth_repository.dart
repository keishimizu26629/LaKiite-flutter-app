abstract class IauthRepository {
  Future<void> logIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
}
