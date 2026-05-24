import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';
import 'package:lakiite/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase Emulatorで新規登録してログインできる', (tester) async {
    await app.startApp(Environment.development);
    await tester.pumpAndSettle();

    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'auth-flow-$unique@example.com';
    const password = 'password123';
    const name = 'Integration User';

    final authRepository = AuthRepository(
      FirebaseAuth.instance,
      UserRepository(),
    );

    final signedUpUser = await authRepository.signUp(email, password, name);
    expect(signedUpUser, isNotNull);
    expect(signedUpUser!.name, name);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(signedUpUser.id)
        .get();
    expect(userDoc.exists, isTrue);

    await authRepository.signOut();
    expect(FirebaseAuth.instance.currentUser, isNull);

    final signedInUser = await authRepository.signIn(email, password);
    expect(signedInUser, isNotNull);
    expect(signedInUser!.id, signedUpUser.id);
    expect(FirebaseAuth.instance.currentUser?.uid, signedUpUser.id);

    await authRepository.signOut();
  });
}
