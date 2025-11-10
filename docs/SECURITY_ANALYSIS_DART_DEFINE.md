# dart_defineファイルのセキュリティ分析

## ファイルの内容

### dev_dart_define.json
- `FLAVOR`: "development" - 公開情報
- `IOS_APP_ID`: "com.inoworl.lakiite.dev" - 公開情報（アプリID）
- `ANDROID_APP_ID`: "com.inoworl.lakiite.dev" - 公開情報（アプリID）
- `APP_NAME`: "LaKiite Dev" - 公開情報
- `FIREBASE_OPTIONS_CLASS`: "DevFirebaseOptions" - 公開情報
- `ADMOB_IOS_APP_ID`: "ca-app-pub-3940256099942544~1458002511" - **テスト用ID（公開）**
- `ADMOB_ANDROID_APP_ID`: "ca-app-pub-3940256099942544~3347511713" - **テスト用ID（公開）**
- `ADMOB_IOS_BANNER_ID`: "ca-app-pub-3940256099942544/2934735716" - **テスト用ID（公開）**
- `ADMOB_ANDROID_BANNER_ID`: "ca-app-pub-3940256099942544/6300978111" - **テスト用ID（公開）**

### prod_dart_define.json
- `FLAVOR`: "production" - 公開情報
- `IOS_APP_ID`: "com.inoworl.lakiite" - 公開情報（アプリID）
- `ANDROID_APP_ID`: "com.inoworl.lakiite" - 公開情報（アプリID）
- `APP_NAME`: "LaKiite" - 公開情報
- `FIREBASE_OPTIONS_CLASS`: "ProdFirebaseOptions" - 公開情報
- `ADMOB_IOS_APP_ID`: "ca-app-pub-6315199114988889~8448676824" - **本番用ID**
- `ADMOB_ANDROID_APP_ID`: "ca-app-pub-6315199114988889~9761758494" - **本番用ID**
- `ADMOB_IOS_BANNER_ID`: "ca-app-pub-6315199114988889/6149762649" - **本番用ID**
- `ADMOB_ANDROID_BANNER_ID`: "ca-app-pub-6315199114988889/4836680971" - **本番用ID**

## セキュリティリスク分析

### ✅ 安全な情報（Git管理可）

1. **テスト用AdMob ID** (`ca-app-pub-3940256099942544`で始まる)
   - Googleが提供する公開のテストID
   - すべての開発者が使用可能
   - Git管理しても問題なし

2. **アプリID、アプリ名、FLAVOR**
   - 公開情報
   - アプリストアで公開される情報
   - Git管理しても問題なし

### ⚠️ 注意が必要な情報

**本番用AdMob ID** (`ca-app-pub-6315199114988889`で始まる)
- **リスク**: 中程度
- **理由**:
  - AdMob IDはアプリのバイナリに含まれるため、リバースエンジニアリングで取得可能
  - ただし、Gitリポジトリに含めることで、より簡単にアクセス可能になる
  - 悪意のあるユーザーがIDを悪用する可能性（広告の不正クリックなど）

## 推奨事項

### オプション1: 現状維持（推奨度: 中）

**メリット:**
- 設定の共有が容易
- チーム開発が簡単
- AdMob IDは一般的に公開情報とされている

**デメリット:**
- リポジトリが公開された場合、本番用IDが漏洩する可能性
- セキュリティのベストプラクティスに反する可能性

**適用条件:**
- プライベートリポジトリ
- チームメンバーが信頼できる
- AdMob IDの漏洩リスクを許容できる

### オプション2: 本番用IDをGit管理から除外（推奨度: 高）

**実装方法:**
1. `dart_define/prod_dart_define.json`を`.gitignore`に追加
2. `dart_define/prod_dart_define.json.template`をGit管理
3. 各開発者がローカルで`prod_dart_define.json`を作成

**メリット:**
- セキュリティのベストプラクティスに準拠
- 本番用IDの漏洩リスクを低減

**デメリット:**
- 設定の共有がやや複雑になる
- 各開発者が手動で設定ファイルを作成する必要がある

### オプション3: 環境変数を使用（推奨度: 最高）

**実装方法:**
1. CI/CDパイプラインで環境変数から設定を読み込む
2. ローカル開発では`.env`ファイルを使用（`.gitignore`に追加）
3. テンプレートファイルのみGit管理

**メリット:**
- 最も安全
- 環境ごとに柔軟に設定可能
- CI/CDとの統合が容易

**デメリット:**
- 実装がやや複雑
- 環境変数の管理が必要

## 現在の状況

- ✅ `dart_define`ファイルは現在Git管理されている
- ✅ `.gitignore`には`dart_define`に関する記述がない
- ⚠️ 本番用AdMob IDが含まれている

## 推奨される対応

### 短期対応（すぐに実施可能）

1. **プライベートリポジトリの場合**: 現状維持で問題なし
2. **公開リポジトリの場合**: 本番用IDをGit管理から除外

### 長期対応（ベストプラクティス）

1. `dart_define/prod_dart_define.json`を`.gitignore`に追加
2. `dart_define/prod_dart_define.json.template`を作成してGit管理
3. READMEに設定手順を記載

## 結論

**現状の判断:**
- テスト用ID: ✅ Git管理して問題なし
- 本番用ID: ⚠️ プライベートリポジトリなら問題なし、公開リポジトリなら除外を推奨

**推奨:**
- プライベートリポジトリ: 現状維持でOK
- 公開リポジトリ: 本番用IDをGit管理から除外
