import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar feature UI state for the date currently selected by the user.
///
/// Keep this provider in the calendar feature because it is presentation state,
/// not a cross-feature application dependency.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
