import 'dart:math';
import '../value/user_id.dart';

class UserIdGenerator {
  static const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random.secure();

  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  static UserId generateUserId() {
    return UserId(generate());
  }
}
