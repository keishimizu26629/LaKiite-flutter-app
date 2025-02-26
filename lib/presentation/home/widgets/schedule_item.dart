import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';

class ScheduleItem extends ConsumerWidget {
  final Schedule schedule;
  final UserModel currentUser;

  const ScheduleItem({
    super.key,
    required this.schedule,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (schedule.ownerId == currentUser.id)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditSchedulePage(
                        schedule: schedule,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<UserModel?>(
          future: ref.read(userRepositoryProvider).getUser(schedule.ownerId),
          builder: (context, snapshot) {
            final ownerName =
                snapshot.hasData ? snapshot.data!.displayName : '読み込み中...';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.description.isNotEmpty) ...[
                  Text(
                    schedule.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                        '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (schedule.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schedule.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '作成者: ${schedule.ownerId == currentUser.id ? '自分' : ownerName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInteractionSection(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInteractionSection() {
    return Consumer(
      builder: (context, ref, _) {
        final interactionState = ref.watch(
          scheduleInteractionNotifierProvider(schedule.id),
        );
        if (interactionState.isLoading) {
          return const SizedBox();
        }
        if (interactionState.error != null) {
          return const SizedBox();
        }
        final reactionCounts = interactionState.reactionCounts;
        final totalReactions =
            reactionCounts.values.fold(0, (sum, count) => sum + count);
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                if (interactionState.reactions.isNotEmpty)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Stack(
                      children: [
                        if (interactionState
                                    .reactionCounts[ReactionType.thinking] !=
                                null &&
                            interactionState
                                    .reactionCounts[ReactionType.thinking]! >
                                0)
                          const Positioned(
                            right: 2,
                            child: Text(
                              '🤔',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        if (interactionState
                                    .reactionCounts[ReactionType.going] !=
                                null &&
                            interactionState
                                    .reactionCounts[ReactionType.going]! >
                                0)
                          Positioned(
                            top: -1,
                            right: interactionState.reactionCounts[
                                            ReactionType.thinking] !=
                                        null &&
                                    interactionState.reactionCounts[
                                            ReactionType.thinking]! >
                                        0
                                ? null
                                : 2,
                            left: interactionState.reactionCounts[
                                            ReactionType.thinking] !=
                                        null &&
                                    interactionState.reactionCounts[
                                            ReactionType.thinking]! >
                                        0
                                ? -2
                                : null,
                            child: const Text(
                              '🙋',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                const SizedBox(width: 4),
                Text(
                  '$totalReactions',
                  style: TextStyle(
                    color: interactionState.reactions.isNotEmpty
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.comment,
              size: 16,
              color: Colors.blue[400],
            ),
            const SizedBox(width: 4),
            Text(
              '${interactionState.commentCount}',
              style: TextStyle(
                color: Colors.blue[400],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
