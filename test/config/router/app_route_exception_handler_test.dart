import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/config/router/app_route_exception_handler.dart';

void main() {
  late List<String> logs;
  late List<String> delegatedLinks;
  late int fallbackCount;

  setUp(() {
    logs = [];
    delegatedLinks = [];
    fallbackCount = 0;
  });

  void handle(String location) {
    handleAppRouteException(
      Uri.parse(location),
      handleDeepLink: (link) async {
        delegatedLinks.add(link);
        return true;
      },
      goToSplash: () => fallbackCount++,
      logInfo: logs.add,
      logWarning: logs.add,
    );
  }

  for (final location in [
    'lakiitedev://friend/search?searchId=QA123456&token=private-query',
    'https://lakiitedev.airbridge.io/friend/search?searchId=QA123456',
    'https://lakiitedev.airbridge.io/short-link?deeplink='
        '${Uri.encodeComponent('lakiitedev://friend/search?searchId=QA123456')}',
  ]) {
    test('招待をそのまま委譲し、検索IDやURLをログへ出さない: $location', () {
      handle(location);

      expect(delegatedLinks, [location]);
      expect(fallbackCount, 0);
      expect(logs, hasLength(1));
      expect(logs.single, isNot(contains('QA123456')));
      expect(logs.single, isNot(contains('searchId')));
      expect(logs.single, isNot(contains('private-query')));
      expect(logs.single, isNot(contains(location)));
    });
  }

  test('未解決のAirbridge LinkはSDKを待ち、ホスト・パス・クエリをログへ出さない', () {
    handle('https://lakiitedev.abr.ge/private-path?token=private-query');

    expect(delegatedLinks, isEmpty);
    expect(fallbackCount, 0);
    expect(logs, hasLength(1));
    expect(logs.single, isNot(contains('lakiitedev.abr.ge')));
    expect(logs.single, isNot(contains('private-path')));
    expect(logs.single, isNot(contains('private-query')));
  });

  test('未対応のルートはスプラッシュへ戻し、受信URLをログへ出さない', () {
    handle('https://unsupported.example/private-path?token=private-query');

    expect(delegatedLinks, isEmpty);
    expect(fallbackCount, 1);
    expect(logs, hasLength(1));
    expect(logs.single, isNot(contains('unsupported.example')));
    expect(logs.single, isNot(contains('private-path')));
    expect(logs.single, isNot(contains('private-query')));
  });
}
