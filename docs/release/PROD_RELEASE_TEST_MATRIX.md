# Prod Release Test Matrix

最終更新: 2026-05-18

## 配信状況

| Platform | 配信経路 | 状態 | 確認 |
| --- | --- | --- | --- |
| iOS | TestFlight | 配信済み | TestFlight上でprod buildを確認 |
| Android | Google Play 内部テスト | 配信成功 | GitHub Actions run `26013746138` |
| Android | Firebase App Distribution | 配信成功 | GitHub Actions run `26013746138` |

Android prod配信run:
https://github.com/keishimizu26629/LaKiite-flutter-app/actions/runs/26013746138

## 考え方

- Mock差し替えで確認できるものは自動テストで担保する。
- Firebase Auth本番、FCM/APNs、OS通知表示、ストア配信経由の署名/権限は実機・実配信で確認する。
- Push通知は「OSとして届くか」と「通知種別ごとの業務ロジック」を分けて確認する。
- iOS/APNsとAndroid/FCM通知チャンネルはOS依存があるため、両OSで最低1種類のPush通知は確認する。
- 通知種別の網羅は片方のOSで実施し、もう片方は代表ケースで確認する。

## 自動テスト対象

| ID | 区分 | テスト種別 | iOS | Android | Mock可否 | 期待結果 |
| --- | --- | --- | --- | --- | --- | --- |
| A-01 | ログイン成功後の遷移 | widget/integration | OK | OK | OK | ログイン後にホーム/カレンダーへ遷移する |
| A-02 | 新規登録成功後の遷移 | widget/integration | OK | OK | OK | 新規登録後に認証状態が更新されホーム/カレンダーへ遷移する |
| A-03 | ログアウト後の遷移 | widget | OK | OK | OK | ログアウト後にログイン画面へ戻る |
| A-04 | 入力バリデーション | widget | OK | OK | OK | 不正入力時に遷移しない |
| A-05 | 認証失敗時 | widget/integration | OK | OK | OK | エラー表示後、ログイン/新規登録画面に留まる |
| A-06 | 予定作成/編集/削除UI | widget/integration | OK | OK | OK | Repository呼び出しと画面状態が正常 |
| A-07 | フレンド/プロフィール表示 | widget/integration | OK | OK | OK | 権限別表示と空状態が正常 |
| A-08 | AdMob設定 | unit/config | OK | OK | OK | dev/prod IDの取り違えを検出できる |
| A-09 | flavor設定 | unit/config | OK | OK | OK | bundle id/application id/icon/AdMob IDの取り違えを検出できる |

確認済みコマンド:

```bash
fvm flutter test test/presentation/auth/auth_home_navigation_test.dart
```

```bash
fvm flutter test integration_test/login_signup_home_navigation_integration_test.dart \
  -d emulator-5554 \
  --flavor dev \
  --dart-define-from-file=dart_define/dev_dart_define.json
```

## 実機・実配信テスト対象

| ID | 区分 | iOS TestFlight | Android内部テスト | 理由 |
| --- | --- | --- | --- | --- |
| M-01 | Firebase Auth本番ログイン | 必須 | 必須 | 実Firebase project、実認証設定の確認 |
| M-02 | Firebase Auth本番新規登録 | 必須 | 必須 | 本番Authにユーザーが作られるか確認 |
| M-03 | FCM token保存 | 必須 | 必須 | 実端末tokenがprod Firestoreへ保存されるか確認 |
| M-04 | Push foreground | 必須 | 必須 | OS/SDKのforeground表示差分を確認 |
| M-05 | Push background | 必須 | 必須 | OS通知表示を確認 |
| M-06 | Push terminated | 必須 | 必須 | アプリ終了状態で通知表示/タップ起動を確認 |
| M-07 | iOS APNs | 必須 | - | APNs証明書、entitlement、TestFlight環境依存 |
| M-08 | Android通知チャンネル | - | 必須 | Android OS通知設定依存 |
| M-09 | バッジ | 必須 | 任意 | iOS中心。Androidは端末/Launcher差分あり |
| M-10 | ストア表示 | 必須 | 必須 | TestFlight/Play配信後のアイコン、名称、バージョン確認 |
| M-11 | AdMob実広告ロード | 必須 | 必須 | 本番AdMob設定と配信版でのロード確認 |
| M-12 | 権限ダイアログ | 必須 | 必須 | OS表示文言、拒否時挙動確認 |

## Push通知種別

| ID | 通知種別 | 発火操作 | 受信者 | iOS | Android | 両OS必須度 | 備考 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N-01 | 友達申請 | AがBへ友達申請 | B | 必須 | 必須 | 高 | 代表Pushとして両OSで確認する |
| N-02 | グループ招待 | AがBをグループ招待 | B | 必須 | 片方代表で可 | 中 | 片OSで種別網羅、もう片OSは余裕があれば確認 |
| N-03 | リアクション | BがAの予定へリアクション | A | 必須 | 片方代表で可 | 中 | 片OSで種別網羅、もう片OSは余裕があれば確認 |
| N-04 | コメント | BがAの予定へコメント | A | 未実装確認 | 未実装確認 | 低 | `addComment` は現状 `TODO: 通知機能は後で実装` |

## Push通知状態

| ID | 状態 | iOS | Android | 期待結果 |
| --- | --- | --- | --- | --- |
| S-01 | Foreground | 必須 | 必須 | アプリ表示中に通知が見える、またはアプリ内処理が走る |
| S-02 | Background | 必須 | 必須 | OS通知として表示される |
| S-03 | Terminated | 必須 | 必須 | アプリ終了状態で届き、タップで起動できる |
| S-04 | 通知タップ | 必須 | 必須 | クラッシュせず起動/復帰する |
| S-05 | 権限拒否 | 片方で可 | 片方で可 | 拒否時にクラッシュしない |
| S-06 | token更新/保存 | 必須 | 必須 | prod Firestoreのユーザーに `fcmToken` が保存される |

## 最小合格ライン

| 優先 | 内容 | iOS | Android |
| --- | --- | --- | --- |
| P0 | prod版を新規インストールできる | 必須 | 必須 |
| P0 | prodログイン/新規登録ができる | 必須 | 必須 |
| P0 | FCM tokenがprod Firestoreに保存される | 必須 | 必須 |
| P0 | 友達申請通知が届く | 必須 | 必須 |
| P0 | Backgroundで通知表示 | 必須 | 必須 |
| P0 | Terminatedで通知表示/タップ起動 | 必須 | 必須 |
| P1 | グループ招待通知 | 必須 | 片方代表で可 |
| P1 | リアクション通知 | 必須 | 片方代表で可 |
| P1 | Foreground表示 | 必須 | 必須 |
| P2 | 権限拒否時 | 片方で可 | 片方で可 |

## 判断メモ

- 「Push通知が届くか」はiOS/Android両方で確認する。
- 「通知種別ごとの業務ロジック」は片方のOSで網羅し、もう片方は代表ケースで確認する。
- 友達申請通知はリリース前P0として両OSで確認する。
- 前日予定通知は現時点のリリース要件から除外する。
- コメント通知は現状未実装扱い。リリース要件に含める場合は別途実装が必要。
