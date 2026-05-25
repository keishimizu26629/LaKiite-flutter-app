import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/main.dart' as app;
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Firebase Emulatorで認証とFirestoreを利用できる', ($) async {
    await app.startApp(Environment.development);
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'patrol-$unique@example.com';
    const password = 'password123';

    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final docRef =
        FirebaseFirestore.instance.collection('patrol_smoke').doc(uid);
    await docRef.set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['email'], email);

    await FirebaseAuth.instance.signOut();
  });
}
