# Flutter プロジェクト統一開発ガイドライン

## Flutter バージョン管理

本プロジェクトでは、Flutter Version Manager (FVM)を使用して Flutter のバージョンを管理します。

### FVM のセットアップ

1. FVM のインストール

```bash
brew tap leoafarias/fvm
brew install fvm
```

2. プロジェクトでの Flutter バージョン設定

```bash
cd lakiite-flutter-app
fvm install 3.19.3
fvm use 3.19.3
```

3. VSCode での設定

- コマンドパレット（Cmd+Shift+P）を開く
- "Flutter: Change SDK"を選択
- "fvm flutter"を選択

### FVM の使用

- Flutter コマンドの実行時は`fvm`をプレフィックスとして使用

```bash
fvm flutter pub get
fvm flutter run
fvm flutter build ios
```

## アーキテクチャ

クリーンアーキテクチャを採用し、以下のレイヤー構成で実装:

```
lib/
├── application/  # 状態管理(Riverpod Notifier)
├── domain/       # ビジネスロジック・エンティティ(Freezedモデル)
├── infrastructure/  # データソース(API通信)
└── presentation/  # UIコンポーネント・ページ
```

## 主要パッケージ

- **状態管理**: Riverpod (v2.3.6)
- **モデル生成**: Freezed (v2.3.2)
- **ルーティング**: go_router (v13.0.0)
- **HTTP クライアント**: Dio (v5.1.1)

## コーディング規約

### コメント規約

1. ドキュメントコメント(///)

   - クラスの説明
   - メソッドの説明
   - パラメータと戻り値の説明

   ```dart
   /// 状態を管理するNotifierクラス
   ///
   /// パラメータ:
   /// - [param] パラメータの説明
   ///
   /// 戻り値:
   /// - 戻り値の説明
   class StateNotifier extends _$StateNotifier {
   ```

2. 通常コメント(//)

   - 処理内容の説明
   - if 文や async 処理の前の説明

   ```dart
   // ローディング状態に設定
   state = const AsyncLoading();

   // データ取得処理を実行
   final result = await repository.getData();
   ```

### 状態管理(Riverpod 2.0)

1. 状態クラス(Freezed)

   ```dart
   @freezed
   class AppState with _$AppState {
     const factory AppState.initial() = _Initial;
     const factory AppState.loading() = _Loading;
     const factory AppState.loaded(List<Data> data) = _Loaded;
     const factory AppState.error(String message) = _Error;
   }
   ```

2. Notifier クラス

   ```dart
   @riverpod
   class DataNotifier extends _$DataNotifier {
     @override
     FutureOr<AppState> build() async {
       return const AppState.initial();
     }

     Future<void> fetchData() async {
       state = const AsyncLoading();
       state = await AsyncValue.guard(() async {
         final data = await _repository.getData();
         return AppState.loaded(data);
       });
     }
   }
   ```

### エンティティ定義(Freezed)

```dart
@freezed
class Entity with _$Entity {
  const factory Entity({
    required String id,
    required String name,
    required DateTime createdAt,
  }) = _Entity;

  factory Entity.fromJson(Map<String, dynamic> json) =>
      _$EntityFromJson(json);
}
```

### ルーティング(go_router)

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
    ],
    redirect: (context, state) {
      // リダイレクトロジック
      return null;
    },
  );
});
```

## ディレクトリ構造

機能ごとにディレクトリを分割し、各機能内で以下の構造を維持:

```
feature/
├── application/  # 状態管理
│   ├── state.dart
│   └── notifier.dart
├── domain/      # モデル・インターフェース
│   ├── entity.dart
│   └── repository.dart
└── presentation/ # UI
    ├── pages/
    └── widgets/
```

## エラーハンドリング

1. AsyncValue.guard を使用した統一的なエラーハンドリング
2. エラー状態の型安全な管理

```dart
state = await AsyncValue.guard(() async {
  try {
    final result = await repository.getData();
    return AppState.loaded(result);
  } catch (e) {
    return AppState.error(e.toString());
  }
});
```

## バージョン管理とコミット手順

コード変更後は必ず以下の手順でバージョン管理を行ってください：

1. **変更のステージング**

   ```bash
   git add <変更したファイル>
   ```

2. **意味のある単位でコミット**

   ```bash
   git commit -m "英語で変更内容を簡潔に説明"
   ```

3. **コミットメッセージの例**

   - 修正: "Fix notification read status in detail page"
   - 新機能: "Add profile image support to search results"
   - 改善: "Improve error handling in WebView components"
   - リファクタリング: "Refactor notification processing for better reliability"

4. **コミット前のレビュー**
   コミット前に変更内容を確認し、不要なコードや誤った修正がないかを確認してください。

   ```bash
   git diff --staged
   ```

5. **複数の変更の分割**
   異なる目的の変更は、それぞれ別のコミットとして分けるようにしてください。

コード品質を維持し、変更履歴を明確にするために、これらの手順を遵守してください。
