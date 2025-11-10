// Presentation層のプロバイダーを一元管理するファイル
//
// このファイルは、Feature別に分割されたプロバイダーを
// 一箇所からexportすることで、後方互換性を保ちます。
//
// 新しいプロバイダーは、適切なFeature別のファイルに追加してください。

// DI層のプロバイダーをexport
export 'package:lakiite/di/repository_providers.dart'
    show
        firebaseAuthProvider,
        authRepositoryProvider,
        userRepositoryProvider,
        groupRepositoryProvider,
        listRepositoryProvider,
        scheduleRepositoryProvider,
        notificationRepositoryProvider,
        friendListRepositoryProvider,
        scheduleInteractionRepositoryProvider,
        reactionRepositoryProvider;

// Application層のプロバイダーをexport
export 'package:lakiite/application/providers/application_providers.dart'
    show
        authStateProvider,
        authNotifierProvider,
        scheduleNotifierProvider,
        groupNotifierProvider,
        listNotifierProvider;

export 'package:lakiite/application/notification/notification_notifier.dart'
    show currentUserIdProvider;

// Presentation層のFeature別プロバイダーをexport
export 'providers/auth_providers.dart'
    show authStateProvider, authNotifierProvider;

export 'providers/schedule_providers.dart'
    show scheduleNotifierProvider, userSchedulesStreamProvider;

export 'providers/group_providers.dart'
    show groupNotifierProvider, userGroupsStreamProvider;

export 'providers/list_providers.dart'
    show listNotifierProvider, userListsStreamProvider, listStreamProvider;

export 'providers/user_providers.dart'
    show userStreamProvider, userFriendsStreamProvider, userFriendsProvider;

export 'providers/common_providers.dart' show selectedDateProvider;
