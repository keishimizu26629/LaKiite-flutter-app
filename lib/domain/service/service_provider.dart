import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/domain/service/group_manager.dart';
import 'package:lakiite/domain/service/list_manager.dart';
import 'package:lakiite/domain/service/user_manager.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

/// グループ管理サービスのプロバイダー
final groupManagerProvider = Provider<IGroupManager>((ref) {
  return GroupManager(
    ref.watch(groupRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
});

/// リスト管理サービスのプロバイダー
final listManagerProvider = Provider<IListManager>((ref) {
  return ListManager(
    ref.watch(listRepositoryProvider),
  );
});

/// ユーザー管理サービスのプロバイダー
final userManagerProvider = Provider<IUserManager>((ref) {
  return UserManager(
    ref.watch(userRepositoryProvider),
  );
});
