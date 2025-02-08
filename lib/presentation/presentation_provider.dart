import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarakite/application/auth/auth_notifier.dart';
import 'package:tarakite/application/auth/auth_state.dart';
import 'package:tarakite/application/group/group_notifier.dart';
import 'package:tarakite/application/group/group_state.dart';
import 'package:tarakite/application/schedule/schedule_notifier.dart';
import 'package:tarakite/application/schedule/schedule_state.dart';
import 'package:tarakite/domain/interfaces/i_group_repository.dart';
import 'package:tarakite/domain/interfaces/i_schedule_repository.dart';
import 'package:tarakite/infrastructure/group_repository.dart';
import 'package:tarakite/infrastructure/schedule_repository.dart';

// Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

// Repository providers
// Note: authRepositoryProvider and userRepositoryProvider are now defined in auth_notifier.dart

final groupRepositoryProvider = Provider<IGroupRepository>((ref) {
  return GroupRepository();
});

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  return ScheduleRepository();
});

// Auth state providers
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final authNotifierProvider = AutoDisposeAsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Group state providers
final groupNotifierProvider = AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);

// Schedule state providers
final scheduleNotifierProvider = AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);
