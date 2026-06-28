import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/friend/friend_search_qr_scanner_page.dart';

void main() {
  group('extractFriendSearchIdFromQrValue', () {
    test('Airbridge招待リンクURLから検索IDを抽出する', () {
      final searchId = extractFriendSearchIdFromQrValue(
        'https://lakiite-dev.inoworl.com/friend_cached?searchId=Pj5I7M58',
      );

      expect(searchId, 'Pj5I7M58');
    });

    test('nested deep linkを含むAirbridge招待リンクURLから検索IDを抽出する', () {
      final searchId = extractFriendSearchIdFromQrValue(
        'https://lakiite-dev.inoworl.com/friend_cached'
        '?deep_link=%2Ffriend%2Fsearch%3FsearchId%3DPj5I7M58',
      );

      expect(searchId, 'Pj5I7M58');
    });

    test('検索ID単体も後方互換として受け付ける', () {
      expect(extractFriendSearchIdFromQrValue('Pj5I7M58'), 'Pj5I7M58');
    });
  });
}
