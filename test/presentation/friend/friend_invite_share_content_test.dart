import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/friend/friend_invite_share_content.dart';

void main() {
  group('FriendInviteShareContent', () {
    test('渡された招待リンクを本文に入れる', () {
      final inviteUrl = Uri.parse('https://abr.ge/abc123');
      final content = FriendInviteShareContent.create(
        inviteUrl: inviteUrl,
        inviterName: '田中太郎',
      );

      expect(content.url, inviteUrl);
      expect(
        content.message,
        'LaKiite（ラキーテ）に招待されています！\n'
        'インストールして田中太郎さんと友達になりましょう！\n'
        '$inviteUrl',
      );
    });

    test('招待者名はtrimして本文に入れる', () {
      final inviteUrl = Uri.parse('https://abr.ge/abc123');
      final content = FriendInviteShareContent.create(
        inviteUrl: inviteUrl,
        inviterName: ' 田中太郎 ',
      );

      expect(content.message, contains('田中太郎さん'));
      expect(content.message, contains(inviteUrl.toString()));
    });

    test('schemeのないURLは拒否する', () {
      expect(
        () => FriendInviteShareContent.create(
          inviteUrl: Uri.parse('abr.ge/abc123'),
          inviterName: '田中太郎',
        ),
        throwsArgumentError,
      );
    });

    test('招待者名が空なら拒否する', () {
      expect(
        () => FriendInviteShareContent.create(
          inviteUrl: Uri.parse('https://abr.ge/abc123'),
          inviterName: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
