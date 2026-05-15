import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _sessionCounterProvider = StateProvider<int>((ref) => 0);

class _SessionCounterView extends ConsumerWidget {
  const _SessionCounterView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_sessionCounterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count:$count'),
        ElevatedButton(
          onPressed: () {
            ref.read(_sessionCounterProvider.notifier).state++;
          },
          child: const Text('increment'),
        ),
      ],
    );
  }
}

class _SessionScopedSubtree extends StatelessWidget {
  const _SessionScopedSubtree({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(userId),
      child: const _SessionCounterView(),
    );
  }
}

void main() {
  testWidgets('userId を切り替えると subtree 配下の provider state がリセットされる',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _SessionScopedSubtree(userId: 'user-a'),
        ),
      ),
    );

    expect(find.text('count:0'), findsOneWidget);

    await tester.tap(find.text('increment'));
    await tester.pumpAndSettle();
    expect(find.text('count:1'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _SessionScopedSubtree(userId: 'user-b'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('count:0'), findsOneWidget);
  });
}
