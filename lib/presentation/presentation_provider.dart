import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../infrastructure/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// AuthRepositoryのプロバイダー
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

// 認証状態のプロバイダー
final authStateProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});