import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../domain/interfaces/i_friend_invite_link_service.dart';

class FriendInviteLinkService implements IFriendInviteLinkService {
  FriendInviteLinkService({
    required FirebaseAuth firebaseAuth,
    required http.Client httpClient,
    required String endpointUrl,
  })  : _firebaseAuth = firebaseAuth,
        _httpClient = httpClient,
        _endpointUrl = endpointUrl;

  factory FriendInviteLinkService.fromAppConfig({
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
  }) {
    return FriendInviteLinkService(
      firebaseAuth: firebaseAuth ?? FirebaseAuth.instance,
      httpClient: httpClient ?? http.Client(),
      endpointUrl: AppConfig.instance.friendInviteLinkUrl,
    );
  }

  final FirebaseAuth _firebaseAuth;
  final http.Client _httpClient;
  final String _endpointUrl;

  @override
  Future<Uri> createInviteLink() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const FriendInviteLinkException('ログインが必要です');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const FriendInviteLinkException('ログインが必要です');
    }
    final response = await _httpClient.post(
      Uri.parse(_endpointUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FriendInviteLinkException(_errorMessageFrom(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['url'] is! String) {
      throw const FriendInviteLinkException('招待リンクの生成に失敗しました');
    }

    final uri = Uri.tryParse(decoded['url'] as String);
    if (uri == null || !uri.hasScheme) {
      throw const FriendInviteLinkException('招待リンクの生成に失敗しました');
    }

    return uri;
  }

  String _errorMessageFrom(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Fall through to the generic message.
    }
    return '招待リンクの生成に失敗しました';
  }
}

class FriendInviteLinkException implements Exception {
  const FriendInviteLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}
