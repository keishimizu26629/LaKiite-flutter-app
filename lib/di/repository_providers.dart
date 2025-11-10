import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/interfaces/i_group_repository.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/interfaces/i_friend_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/domain/repository/reaction_repository.dart';
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/infrastructure/group_repository.dart';
import 'package:lakiite/infrastructure/list_repository.dart';
import 'package:lakiite/infrastructure/schedule_repository.dart';
import 'package:lakiite/infrastructure/notification_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';
import 'package:lakiite/infrastructure/friend_list_repository.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';
import 'package:lakiite/infrastructure/repository/reaction_repository_impl.dart';

/// Firebase認証インスタンスを提供するプロバイダー
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

/// 認証リポジトリプロバイダー
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// リポジトリプロバイダー群
///
/// Infrastructure層の実装をDomain層のインターフェースとして提供します。
/// このファイルはDI層（Dependency Injection層）として、レイヤー間の依存関係を管理します。

/// ユーザーリポジトリプロバイダー
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final repository = UserRepository();
  ref.onDispose(() {
    // キャッシュをクリア
    (repository).clearCache();
  });
  return repository;
});

/// グループリポジトリプロバイダー
final groupRepositoryProvider = Provider<IGroupRepository>((ref) {
  return GroupRepository();
});

/// リストリポジトリプロバイダー
final listRepositoryProvider = Provider<IListRepository>((ref) {
  return ListRepository();
});

/// スケジュールリポジトリプロバイダー
final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  return ScheduleRepository();
});

/// 通知リポジトリプロバイダー
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// フレンドリストリポジトリプロバイダー
final friendListRepositoryProvider = Provider<IFriendListRepository>((ref) {
  return FriendListRepository();
});

/// スケジュールインタラクションリポジトリプロバイダー
final scheduleInteractionRepositoryProvider =
    Provider<IScheduleInteractionRepository>((ref) {
  return ScheduleInteractionRepository();
});

/// リアクションリポジトリプロバイダー
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return ReactionRepositoryImpl(firestore);
});
