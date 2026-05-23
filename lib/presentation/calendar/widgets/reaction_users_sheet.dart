import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/widgets/default_user_icon.dart';
import 'package:lakiite/presentation/widgets/reaction_type_view_extension.dart';

/// 予定にリアクションしたユーザーを表示するBottomSheet。
///
/// データ取得済みのリアクションとユーザー取得Futureを受け取り、表示状態だけを扱う。
class ReactionUsersSheet extends StatelessWidget {
  const ReactionUsersSheet({
    super.key,
    required this.reactions,
    required this.usersFuture,
  });

  final List<Reaction> reactions;
  final Future<List<UserModel>> usersFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'リアクションした人',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<UserModel>>(
            future: usersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('エラー: ${snapshot.error}'));
              }

              final users = snapshot.data!;
              developer.log('リアクションユーザー: ${users.length}人');
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final reaction = reactions[index];
                    developer.log('リアクションオブジェクト: $reaction');
                    developer.log(
                      'リアクションタイプ: ${reaction.type} (${reaction.type.runtimeType})',
                    );

                    return ListTile(
                      leading: Stack(
                        children: [
                          user.iconUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(user.iconUrl!),
                                )
                              : const DefaultUserIcon(),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Text(
                              reaction.type.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      title: Text(user.displayName),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
