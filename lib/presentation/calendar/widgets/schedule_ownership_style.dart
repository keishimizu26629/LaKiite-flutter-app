import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/service/display_list_membership.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';

class ScheduleOwnershipStyle {
  const ScheduleOwnershipStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  factory ScheduleOwnershipStyle.resolve(
    BuildContext context, {
    required Schedule schedule,
    required String? currentUserId,
    Iterable<DisplayList> displayLists = const [],
    double backgroundAlpha = 0.1,
    double borderAlpha = 0.8,
    double primaryTextAlpha = 0.85,
    Color? ownerBackgroundColor,
    Color? ownerBorderColor,
    Color? ownerTextColor,
  }) {
    final isOwner = isOwnedByCurrentUser(schedule, currentUserId);
    if (isOwner) {
      return ScheduleOwnershipStyle(
        backgroundColor:
            ownerBackgroundColor ?? Colors.grey.withValues(alpha: 0.1),
        borderColor: ownerBorderColor ?? Colors.grey.withValues(alpha: 0.8),
        textColor: ownerTextColor ?? Colors.grey.shade700,
      );
    }

    final displayList = DisplayListMembership.findListForUser(
      displayLists: displayLists,
      userId: schedule.ownerId,
    );
    final primaryColor = displayList == null
        ? Theme.of(context).primaryColor
        : DisplayListPalette.colorForKey(displayList.colorKey);
    return ScheduleOwnershipStyle(
      backgroundColor: primaryColor.withValues(alpha: backgroundAlpha),
      borderColor: primaryColor.withValues(alpha: borderAlpha),
      textColor: primaryColor.withValues(alpha: primaryTextAlpha),
    );
  }

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  static bool isOwnedByCurrentUser(Schedule schedule, String? currentUserId) {
    return currentUserId != null && schedule.ownerId == currentUserId;
  }
}
