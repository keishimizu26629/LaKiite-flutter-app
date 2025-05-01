import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfile {
  final String displayName;
  final String searchId;
  final String? iconUrl;
  final String? shortBio;

  const PublicProfile({
    required this.displayName,
    required this.searchId,
    this.iconUrl,
    this.shortBio,
  });

  factory PublicProfile.fromFirestore(Map<String, dynamic> data) {
    return PublicProfile(
      displayName: data['displayName'] as String,
      searchId: data['searchId'] as String,
      iconUrl: data['iconUrl'] as String?,
      shortBio: data['shortBio'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'searchId': searchId,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (shortBio != null) 'shortBio': shortBio,
    };
  }
}

class PrivateProfile {
  final String name;
  final List<String> lists;
  final DateTime createdAt;
  final String? fcmToken;

  const PrivateProfile({
    required this.name,
    required this.lists,
    required this.createdAt,
    this.fcmToken,
  });

  factory PrivateProfile.fromFirestore(Map<String, dynamic> data) {
    return PrivateProfile(
      name: data['name'] as String? ?? '',
      lists: List<String>.from(data['lists'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lists': lists,
      'createdAt': Timestamp.fromDate(createdAt),
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }
}

class UserProfile {
  final String id;
  final PublicProfile publicProfile;
  final PrivateProfile privateProfile;
  final List<String> friends;
  final List<String> groups;
  final String? fcmToken;

  const UserProfile({
    required this.id,
    required this.publicProfile,
    required this.privateProfile,
    required this.friends,
    required this.groups,
    this.fcmToken,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      publicProfile: PublicProfile.fromFirestore(data),
      privateProfile: PrivateProfile.fromFirestore(data['private'] ?? {}),
      friends: List<String>.from(data['friends'] ?? []),
      groups: List<String>.from(data['groups'] ?? []),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      ...publicProfile.toFirestore(),
      'private': privateProfile.toFirestore(),
      'friends': friends,
      'groups': groups,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  UserProfile copyWith({
    String? id,
    PublicProfile? publicProfile,
    PrivateProfile? privateProfile,
    List<String>? friends,
    List<String>? groups,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id ?? this.id,
      publicProfile: publicProfile ?? this.publicProfile,
      privateProfile: privateProfile ?? this.privateProfile,
      friends: friends ?? this.friends,
      groups: groups ?? this.groups,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
