/// グループメンバー招待時の検索結果ユーザーモデル
class SearchUserModel {
  const SearchUserModel({
    required this.id,
    required this.displayName,
    required this.searchId,
    required this.iconUrl,
    this.hasPendingRequest = false,
  });

  final String id;
  final String displayName;
  final String searchId;
  final String iconUrl;
  final bool hasPendingRequest;
}
