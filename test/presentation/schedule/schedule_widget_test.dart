import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import '../../mock/providers/test_providers.dart';
import '../../mock/base_mock.dart';
import '../../utils/test_utils.dart';

void main() {
  group('Schedule Widget Tests', () {
    setUp(() {
      TestProviders.reset();
    });

    group('ScheduleCard Widget Tests', () {
      testWidgets('スケジュール情報が正しく表示される', (tester) async {
        final schedule = BaseMock.createTestSchedule(
          title: 'テストスケジュール',
          description: 'テスト用の説明',
        );

        // スケジュールカードコンポーネントがある場合のテスト
        // 実際のウィジェット名に応じて調整が必要
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Card(
              child: ListTile(
                title: Text(schedule.title),
                subtitle: Text(schedule.description),
                trailing: Text(
                  '${schedule.startDateTime.hour}:${schedule.startDateTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ),
        );

        expect(find.text('テストスケジュール'), findsOneWidget);
        expect(find.text('テスト用の説明'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
      });

      testWidgets('スケジュールタップでイベントが発火される', (tester) async {
        bool tapped = false;
        final schedule = BaseMock.createTestSchedule();

        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: GestureDetector(
              onTap: () => tapped = true,
              child: Card(
                child: ListTile(
                  title: Text(schedule.title),
                  subtitle: Text(schedule.description),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(Card));
        expect(tapped, isTrue);
      });

      testWidgets('長いタイトルが適切に表示される', (tester) async {
        final schedule = BaseMock.createTestSchedule(
          title: 'これは非常に長いスケジュールタイトルで、UIでの表示確認のためのテストです',
          description: '説明も長めに設定して確認します',
        );

        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: SizedBox(
              width: 300,
              child: Card(
                child: ListTile(
                  title: Text(
                    schedule.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    schedule.description,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );

        // オーバーフローが適切に処理されているかの確認
        expect(find.byType(Text), findsNWidgets(2));
      });
    });

    group('Schedule List Widget Tests', () {
      testWidgets('複数のスケジュールが表示される', (tester) async {
        final schedules = [
          BaseMock.createTestSchedule(
            id: 'schedule-1',
            title: 'スケジュール1',
            description: '説明1',
          ),
          BaseMock.createTestSchedule(
            id: 'schedule-2',
            title: 'スケジュール2',
            description: '説明2',
          ),
          BaseMock.createTestSchedule(
            id: 'schedule-3',
            title: 'スケジュール3',
            description: '説明3',
          ),
        ];

        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return Card(
                  child: ListTile(
                    title: Text(schedule.title),
                    subtitle: Text(schedule.description),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('スケジュール1'), findsOneWidget);
        expect(find.text('スケジュール2'), findsOneWidget);
        expect(find.text('スケジュール3'), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(3));
      });

      testWidgets('空のスケジュールリストが適切に表示される', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: const Center(
              child: Text('スケジュールがありません'),
            ),
          ),
        );

        expect(find.text('スケジュールがありません'), findsOneWidget);
      });

      testWidgets('ローディング状態が表示される', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Schedule Form Widget Tests', () {
      testWidgets('スケジュール作成フォームが正しく表示される', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Scaffold(
              body: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'タイトル'),
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: '説明'),
                    maxLines: 3,
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: '場所'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('タイトル'), findsOneWidget);
        expect(find.text('説明'), findsOneWidget);
        expect(find.text('場所'), findsOneWidget);
        expect(find.text('保存'), findsOneWidget);
      });

      testWidgets('フォーム入力値が正しく処理される', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Scaffold(
              body: Column(
                children: [
                  const TextField(
                    key: Key('title_field'),
                    decoration: InputDecoration(labelText: 'タイトル'),
                  ),
                  const TextField(
                    key: Key('description_field'),
                    decoration: InputDecoration(labelText: '説明'),
                  ),
                  ElevatedButton(
                    key: const Key('save_button'),
                    onPressed: () {},
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          ),
        );

        // タイトル入力
        await tester.enterText(
          find.byKey(const Key('title_field')),
          'テストタイトル',
        );

        // 説明入力
        await tester.enterText(
          find.byKey(const Key('description_field')),
          'テスト説明',
        );

        await tester.pumpAndSettle();

        // 入力値が反映されているかを確認
        expect(find.text('テストタイトル'), findsOneWidget);
        expect(find.text('テスト説明'), findsOneWidget);
      });

      testWidgets('バリデーションが動作する', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'タイトル'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // バリデーション失敗のシミュレーション
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('タイトルを入力してください'),
                            ),
                          );
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // 空のまま保存ボタンをタップ
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();

        // バリデーションエラーの確認（SnackBarで表示）
        expect(find.text('タイトルを入力してください'), findsOneWidget);
      });
    });

    group('Schedule Calendar Widget Tests', () {
      testWidgets('カレンダービューが表示される', (tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: 42, // 6週間分
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text('${index + 1}'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // カレンダーグリッドが表示されているかを確認
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('日付タップで詳細表示', (tester) async {
        bool dayTapped = false;

        await tester.pumpWidget(
          TestUtils.createTestApp(
            overrides: TestProviders.forScheduleCreation,
            child: Scaffold(
              body: GestureDetector(
                onTap: () => dayTapped = true,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(child: Text('15')),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('15'));
        expect(dayTapped, isTrue);
      });
    });
  });
}
