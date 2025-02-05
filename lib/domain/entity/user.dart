import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String name,
    required String displayName,
    required String userId,
    required List<String> friends,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  factory UserModel.create({
    required String id,
    required String name,
  }) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final userId = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();

    return UserModel(
      id: id,
      name: name,
      displayName: name,
      userId: userId,
      friends: const [],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String,
      displayName: data['displayName'] as String,
      userId: data['userId'] as String,
      friends: List<String>.from(data['friends'] as List),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'displayName': displayName,
      'userId': userId,
      'friends': friends,
    };
  }
}
