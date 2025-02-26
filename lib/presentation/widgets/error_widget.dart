import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class ScheduleErrorWidget extends StatelessWidget {
  final Object error;
  final AuthState state;
  final WidgetRef ref;

  const ScheduleErrorWidget({
    super.key,
    required this.error,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました: $error',
            style: TextStyle(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(scheduleNotifierProvider.notifier)
                  .watchUserSchedules(state.user!.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}
