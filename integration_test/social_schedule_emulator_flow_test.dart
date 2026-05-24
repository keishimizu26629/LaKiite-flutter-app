import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/application/notification/accept_friend_request_use_case.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/infrastructure/notification_repository.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';
import 'package:lakiite/infrastructure/schedule_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';
import 'package:lakiite/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase Emulatorで主要な共有フローを実行できる', (tester) async {
    await app.startApp(Environment.development);
    await tester.pumpAndSettle();

    final unique = DateTime.now().microsecondsSinceEpoch;
    final authRepository = AuthRepository(
      FirebaseAuth.instance,
      UserRepository(),
    );
    final userRepository = UserRepository();
    final scheduleRepository = ScheduleRepository();
    final interactionRepository = ScheduleInteractionRepository();
    final notificationRepository = NotificationRepository();

    final sender = await authRepository.signUp(
      'sender-$unique@example.com',
      'password123',
      'Sender User',
    );
    expect(sender, isNotNull);

    await authRepository.signOut();

    final receiver = await authRepository.signUp(
      'receiver-$unique@example.com',
      'password123',
      'Receiver User',
    );
    expect(receiver, isNotNull);

    final friendRequest = domain.Notification.createFriendRequest(
      fromUserId: sender!.id,
      toUserId: receiver!.id,
      fromUserDisplayName: sender.displayName,
      toUserDisplayName: receiver.displayName,
    );
    await notificationRepository.createNotification(friendRequest);

    final requestSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('sendUserId', isEqualTo: sender.id)
        .where('receiveUserId', isEqualTo: receiver.id)
        .where('type', isEqualTo: domain.NotificationType.friend.name)
        .limit(1)
        .get();
    expect(requestSnapshot.docs, hasLength(1));

    final requestId = requestSnapshot.docs.single.id;
    await AcceptFriendRequestUseCase(
      notificationRepository: notificationRepository,
      userRepository: userRepository,
    ).execute(requestId);

    final accepted = await notificationRepository.getNotification(requestId);
    expect(accepted?.status, domain.NotificationStatus.accepted);
    expect(accepted?.isRead, isTrue);

    final receiverPrivate = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiver.id)
        .collection('private')
        .doc('profile')
        .get();
    expect(receiverPrivate.data()?['lists'], contains(sender.id));

    final start = DateTime.now().add(const Duration(days: 1));
    final schedule = await scheduleRepository.createSchedule(
      Schedule(
        id: '',
        title: 'Integration schedule $unique',
        description: 'Created by integration test',
        location: 'Emulator',
        startDateTime: start,
        endDateTime: start.add(const Duration(hours: 1)),
        ownerId: receiver.id,
        ownerDisplayName: receiver.displayName,
        ownerPhotoUrl: receiver.iconUrl,
        sharedLists: const [],
        visibleTo: [receiver.id, sender.id],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    expect(schedule.id, isNotEmpty);

    final commentId = await interactionRepository.addComment(
      schedule.id,
      receiver.id,
      'Integration comment',
    );
    expect(commentId, isNotEmpty);

    final reactionId = await interactionRepository.addReaction(
      schedule.id,
      receiver.id,
      ReactionType.going,
    );
    expect(reactionId, receiver.id);

    final comments = await interactionRepository.getComments(schedule.id);
    expect(comments.map((comment) => comment.content),
        contains('Integration comment'));

    final reactions = await interactionRepository.getReactions(schedule.id);
    expect(reactions.map((reaction) => reaction.userId), contains(receiver.id));

    final renamed = receiver.updateProfile(displayName: 'Renamed User');
    await userRepository.updateUser(renamed);
    final renamedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiver.id)
        .get();
    expect(renamedDoc.data()?['displayName'], 'Renamed User');

    final iconUrl = await userRepository.uploadUserIcon(
      receiver.id,
      Uint8List.fromList(_onePixelJpeg),
    );
    expect(iconUrl, isNotNull);
    expect(iconUrl, contains('v1%2Fusers%2Ficon%2F${receiver.id}'));

    final iconDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiver.id)
        .get();
    expect(iconDoc.data()?['iconUrl'], iconUrl);

    await authRepository.signOut();
  });
}

const _onePixelJpeg = <int>[
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x01,
  0x00,
  0x48,
  0x00,
  0x48,
  0x00,
  0x00,
  0xFF,
  0xDB,
  0x00,
  0x43,
  0x00,
  0xFF,
  0xC0,
  0x00,
  0x0B,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xFF,
  0xC4,
  0x00,
  0x14,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xFF,
  0xDA,
  0x00,
  0x08,
  0x01,
  0x01,
  0x00,
  0x00,
  0x3F,
  0x00,
  0xD2,
  0xCF,
  0x20,
  0xFF,
  0xD9,
];
