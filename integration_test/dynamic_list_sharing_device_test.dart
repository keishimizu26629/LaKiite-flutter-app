import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/infrastructure/auth_repository.dart';
import 'package:lakiite/infrastructure/list_repository.dart';
import 'package:lakiite/infrastructure/schedule_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';
import 'package:lakiite/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dev Firebaseでリスト変更が既存予定の公開範囲へ反映される', (tester) async {
    await app.startApp(Environment.development);
    await tester.pumpAndSettle();

    final unique = DateTime.now().microsecondsSinceEpoch;
    final authRepository = AuthRepository(
      FirebaseAuth.instance,
      UserRepository(),
    );
    final userRepository = UserRepository();
    final listRepository = ListRepository();
    final scheduleRepository = ScheduleRepository();

    final userA = await _signUpUser(
      authRepository,
      email: 'dynamic-list-a-$unique@example.com',
      name: 'Dynamic List A',
    );
    await authRepository.signOut();

    final userB = await _signUpUser(
      authRepository,
      email: 'dynamic-list-b-$unique@example.com',
      name: 'Dynamic List B',
    );
    await authRepository.signOut();

    final userC = await _signUpUser(
      authRepository,
      email: 'dynamic-list-c-$unique@example.com',
      name: 'Dynamic List C',
    );
    await authRepository.signOut();

    await _signIn(authRepository, userA);
    await userRepository.addToList(userA.id, userB.id);
    await userRepository.addToList(userA.id, userC.id);
    await authRepository.signOut();

    await _signIn(authRepository, userB);
    await userRepository.addToList(userB.id, userA.id);
    await authRepository.signOut();

    await _signIn(authRepository, userC);
    await userRepository.addToList(userC.id, userA.id);
    await authRepository.signOut();

    await _signIn(authRepository, userA);
    final listA = await listRepository.createList(
      listName: 'list-a-$unique',
      memberIds: [userB.id],
      ownerId: userA.id,
    );

    final schedule1 = await _createSchedule(
      scheduleRepository,
      owner: userA,
      title: 'dynamic-list-schedule-1-$unique',
      sharedLists: [listA.id],
      visibleTo: [userA.id, userB.id],
      daysFromNow: 1,
    );

    await _expectScheduleVisibleFromUser(
      authRepository,
      userB,
      schedule1.id,
      isVisible: true,
    );
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule1.id,
      isVisible: false,
    );

    await _signIn(authRepository, userA);
    await listRepository.addMember(listA.id, userC.id);
    await _waitForVisibleTo(schedule1.id, userC.id, isVisible: true);
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule1.id,
      isVisible: true,
    );

    await _signIn(authRepository, userA);
    final listB = await listRepository.createList(
      listName: 'list-b-$unique',
      memberIds: [userC.id],
      ownerId: userA.id,
    );

    final schedule2 = await _createSchedule(
      scheduleRepository,
      owner: userA,
      title: 'dynamic-list-schedule-2-$unique',
      sharedLists: [listA.id, listB.id],
      visibleTo: [userA.id, userB.id, userC.id],
      daysFromNow: 2,
    );

    await listRepository.removeMember(listA.id, userC.id);
    await _waitForVisibleTo(schedule2.id, userC.id, isVisible: true);
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule2.id,
      isVisible: true,
    );

    await _signIn(authRepository, userA);
    await listRepository.removeMember(listB.id, userC.id);
    await _waitForVisibleTo(schedule2.id, userC.id, isVisible: false);
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule2.id,
      isVisible: false,
    );

    await _signIn(authRepository, userA);
    await listRepository.addMember(listB.id, userC.id);
    await _waitForVisibleTo(schedule2.id, userC.id, isVisible: true);
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule2.id,
      isVisible: true,
    );

    await _signIn(authRepository, userA);
    await listRepository.deleteList(listB.id);
    await _waitForVisibleTo(schedule2.id, userC.id, isVisible: false);
    await _expectScheduleVisibleFromUser(
      authRepository,
      userC,
      schedule2.id,
      isVisible: false,
    );

    await authRepository.signOut();
  });
}

class _TestAccount {
  const _TestAccount({
    required this.user,
    required this.email,
  });

  final UserModel user;
  final String email;

  String get id => user.id;
  String get displayName => user.displayName;
  String? get iconUrl => user.iconUrl;
}

Future<_TestAccount> _signUpUser(
  AuthRepository authRepository, {
  required String email,
  required String name,
}) async {
  final user = await authRepository.signUp(email, 'password123', name);
  expect(user, isNotNull);
  return _TestAccount(user: user!, email: email);
}

Future<void> _signIn(AuthRepository authRepository, _TestAccount user) async {
  await authRepository.signOut();
  final signedIn = await authRepository.signIn(user.email, 'password123');
  expect(signedIn?.id, user.id);
}

Future<Schedule> _createSchedule(
  ScheduleRepository scheduleRepository, {
  required _TestAccount owner,
  required String title,
  required List<String> sharedLists,
  required List<String> visibleTo,
  required int daysFromNow,
}) {
  final start = DateTime.now().add(Duration(days: daysFromNow));
  final now = DateTime.now();
  return scheduleRepository.createSchedule(
    Schedule(
      id: '',
      title: title,
      description: 'Created by dynamic list sharing integration test',
      location: 'dev Firebase',
      startDateTime: start,
      endDateTime: start.add(const Duration(hours: 1)),
      ownerId: owner.id,
      ownerDisplayName: owner.displayName,
      ownerPhotoUrl: owner.iconUrl,
      sharedLists: sharedLists,
      visibleTo: visibleTo,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<void> _waitForVisibleTo(
  String scheduleId,
  String userId, {
  required bool isVisible,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));

  while (DateTime.now().isBefore(deadline)) {
    final doc = await FirebaseFirestore.instance
        .collection('schedules')
        .doc(scheduleId)
        .get(const GetOptions(source: Source.server));
    final data = doc.data();
    final visibleTo = List<String>.from(data?['visibleTo'] as List? ?? []);

    if (visibleTo.contains(userId) == isVisible) {
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));
  }

  fail(
    'schedules/$scheduleId visibleTo did not become '
    '${isVisible ? 'visible' : 'hidden'} for $userId',
  );
}

Future<void> _expectScheduleVisibleFromUser(
  AuthRepository authRepository,
  _TestAccount user,
  String scheduleId, {
  required bool isVisible,
}) async {
  await _signIn(authRepository, user);
  final schedules = await ScheduleRepository().getUserSchedules(user.id);
  final containsSchedule =
      schedules.any((schedule) => schedule.id == scheduleId);

  expect(containsSchedule, isVisible);
}
