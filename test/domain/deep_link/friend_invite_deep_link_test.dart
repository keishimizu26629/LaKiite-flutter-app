import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/deep_link/friend_invite_deep_link.dart';

void main() {
  group('FriendInviteDeepLink.tryParse', () {
    test('scheme deep linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'lakiite://friend/search?searchId=ABCD1234',
      );

      expect(deepLink?.searchId, 'ABCD1234');
    });

    test('dev scheme deep linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'lakiitedev://friend/search?searchId=MNOP3456',
      );

      expect(deepLink?.searchId, 'MNOP3456');
    });

    test('Airbridge App Linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiite.airbridge.io/friend/search?search_id=EFGH5678',
      );

      expect(deepLink?.searchId, 'EFGH5678');
    });

    test('Airbridge短縮ドメインのApp Linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiite.abr.ge/friend/search?searchId=IJKL9012',
      );

      expect(deepLink?.searchId, 'IJKL9012');
    });

    test('Airbridge dev App Linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/friend/search?searchId=QRST7890',
      );

      expect(deepLink?.searchId, 'QRST7890');
    });

    test('実際のdev招待URLから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('Airbridge tracking pathのURLから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/abc123?searchId=Pj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('Airbridge custom domainのURLから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiite-dev.inoworl.com/friend/search?searchId=Pj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('Airbridgeのnested scheme deep linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/abc123'
        '?deeplink_url=lakiitedev%3A%2F%2Ffriend%2Fsearch%3FsearchId%3DPj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('Airbridgeのnested path deep linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/abc123'
        '?deep_link=%2Ffriend%2Fsearch%3FsearchId%3DPj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('Airbridge custom domainのnested path deep linkから検索IDを抽出する', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiite-dev.inoworl.com/friend_xfrhk82o08rg1555q'
        '?deep_link=%2Ffriend%2Fsearch%3FsearchId%3DPj5I7M58',
      );

      expect(deepLink?.searchId, 'Pj5I7M58');
    });

    test('招待URLではないURLはnullを返す', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://example.com/friend/search?searchId=ABCD1234',
      );

      expect(deepLink, isNull);
    });

    test('不正にencodeされたnested URLはnullを返す', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'https://lakiitedev.airbridge.io/abc123?deeplink_url=%',
      );

      expect(deepLink, isNull);
    });

    test('scheme deep linkでも招待URLではない場合はnullを返す', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'lakiite://settings?searchId=ABCD1234',
      );

      expect(deepLink, isNull);
    });

    test('検索IDが8桁の英数字でない場合はnullを返す', () {
      final deepLink = FriendInviteDeepLink.tryParse(
        'lakiite://friend/search?searchId=invalid-search-id',
      );

      expect(deepLink, isNull);
    });
  });
}
