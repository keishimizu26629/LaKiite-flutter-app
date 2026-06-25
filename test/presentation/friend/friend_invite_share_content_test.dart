import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/presentation/friend/friend_invite_share_content.dart';

void main() {
  group('FriendInviteShareContent', () {
    test('developmentではlakiitedevのAirbridge招待リンクを作る', () {
      final content = FriendInviteShareContent.create(
        searchId: 'Pj5I7M58',
        environment: Environment.development,
      );

      expect(
        content.url,
        Uri.parse(
          'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58',
        ),
      );
      expect(content.message, contains('LaKiite'));
      expect(content.message, contains(content.url.toString()));
    });

    test('productionではlakiiteのAirbridge招待リンクを作る', () {
      final content = FriendInviteShareContent.create(
        searchId: 'Pj5I7M58',
        environment: Environment.production,
      );

      expect(
        content.url,
        Uri.parse(
          'https://lakiite.airbridge.io/friend/search?searchId=Pj5I7M58',
        ),
      );
      expect(content.message, contains(content.url.toString()));
    });

    test('検索IDはtrimしてURL queryに入れる', () {
      final content = FriendInviteShareContent.create(
        searchId: ' Pj5I7M58 ',
        environment: Environment.development,
      );

      expect(content.url.queryParameters['searchId'], 'Pj5I7M58');
      expect(content.message, contains('Pj5I7M58'));
    });
  });
}
