# 予定暗号化 Firestore フィールド

更新日: 2026-06-11

## 対象読者

- 予定・コメントの暗号化実装を触る開発者
- Firestore 上の schedule / comment ドキュメントを調査する開発者
- 移行期間中の `pending` / `migration` フィールドの意味を確認したい運用者

## 目的

暗号化された予定とコメントの Firestore フィールドについて、どの値が何を意味し、復号や公開範囲制御にどう使われるかを整理する。

実データの暗号文、URL、秘密値はこのドキュメントには載せない。ここでは構造と意味だけを扱う。

## 全体像

予定は、本文と鍵を分けて保存する。

- `encryptedPayload`: 予定本文を暗号化したもの
- `encryptedKeys`: ユーザーごとに暗号化した予定鍵
- `migrationEncryptedKeys`: 移行期間用の公開鍵で暗号化した予定鍵
- `pendingEncryptedRecipients`: まだ公開鍵がなく、後から公開対象に昇格するユーザー

コメントは、親予定の予定鍵を使ってコメント本文だけを暗号化する。コメントごとの `encryptedKeys` は持たない。

## 用語

### ユーザー鍵

ユーザー単位の X25519 鍵ペア。

- 公開鍵は `users/{uid}/encryption/current.publicKey` に保存される。
- 秘密鍵は端末ローカルに保存される。
- バックアップ設定済みの場合、秘密鍵はパスワード由来鍵で暗号化され、`encryptedPrivateKeyBackup` として Firestore に保存される。

### 予定鍵

予定ごとに生成される 32 byte の AES-GCM 鍵。予定本文とコメント本文の暗号化に使う。

予定鍵自体は平文保存しない。閲覧可能なユーザーごとに、そのユーザーの公開鍵で暗号化して `encryptedKeys.{uid}` に保存する。

### 移行用鍵

公開鍵をまだ持っていないユーザーがいる移行期間のための共通鍵ペア。

- 公開鍵は `encryptionMigration/current` に保存される。
- 秘密鍵は Secret Manager の `SCHEDULE_MIGRATION_PRIVATE_KEY` に保存される。
- クライアントは移行用公開鍵だけを読み、予定鍵を `migrationEncryptedKeys` に保存する。
- Functions は移行用秘密鍵で予定鍵を復号し、後から公開鍵が作られたユーザー向けに `encryptedKeys.{uid}` を作る。

## schedules/{scheduleId}

### 通常フィールド

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `ownerId` | string | 予定作成者の UID。 |
| `ownerDisplayName` | string | 予定作成時点の作成者表示名。 |
| `ownerPhotoUrl` | string/null | 予定作成時点の作成者アイコン URL。 |
| `startDateTime` | string | 開始日時。現行 mapper では ISO 8601 string として保存する。 |
| `endDateTime` | string | 終了日時。現行 mapper では ISO 8601 string として保存する。 |
| `isAllDay` | boolean | 終日予定かどうか。 |
| `sharedLists` | array<string> | 予定を公開するリスト ID。 |
| `visibleTo` | array<string> | Firestore Rules とクエリで参照する閲覧可能ユーザー UID。クライアント作成・更新時は owner のみを初期値として送り、Functions が `sharedLists` からサーバー側で再計算する。暗号化予定では「復号可能なユーザー」だけを入れる。 |
| `reactionCount` | int | リアクション数のキャッシュ。Functions で更新される。 |
| `commentCount` | int | コメント数のキャッシュ。Functions で更新される。 |
| `createdAt` | string | 作成日時。現行 mapper では ISO 8601 string として保存する。 |
| `updatedAt` | string/timestamp | 更新日時。クライアント作成時は ISO 8601 string、Functions 更新時は server timestamp になることがある。 |

### 暗号化フラグ

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `encrypted` | boolean | `true` の場合、この予定の `title` / `description` / `location` は平文フィールドではなく `encryptedPayload` から復号する。 |
| `encryptionVersion` | int | 予定暗号化スキーマのバージョン。現行は `1`。 |

`encrypted != true` の既存予定は後方互換として平文の `title` / `description` / `location` を読む。

### encryptedPayload

予定本文を予定鍵で AES-GCM 暗号化した payload。

暗号化前の JSON は次の形。

```json
{
  "title": "予定タイトル",
  "description": "説明",
  "location": "場所またはnull"
}
```

Firestore 上の構造。

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `encryptedPayload.algorithm` | string | 本文暗号化方式。現行は `AES-GCM`。 |
| `encryptedPayload.cipherText` | string | 暗号化された本文 JSON。Base64 URL エンコード。 |
| `encryptedPayload.nonce` | string | AES-GCM nonce。Base64 URL エンコード。 |
| `encryptedPayload.mac` | string | AES-GCM authentication tag。Base64 URL エンコード。 |

クライアントは `encryptedKeys.{currentUserId}` から予定鍵を復号し、その予定鍵で `encryptedPayload` を復号する。

### encryptedKeys

予定鍵をユーザーごとの公開鍵で暗号化した map。

キーは UID。値は `ScheduleEncryptedKey`。

```json
{
  "{uid}": {
    "algorithm": "X25519+AES-GCM",
    "encryptedScheduleKey": "...",
    "ephemeralPublicKey": "...",
    "keyVersion": 1,
    "mac": "...",
    "nonce": "..."
  }
}
```

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `encryptedKeys.{uid}.algorithm` | string | 予定鍵のラップ方式。現行は `X25519+AES-GCM`。 |
| `encryptedKeys.{uid}.encryptedScheduleKey` | string | 対象ユーザー向けに暗号化された予定鍵。 |
| `encryptedKeys.{uid}.ephemeralPublicKey` | string | 鍵交換に使う一時公開鍵。 |
| `encryptedKeys.{uid}.keyVersion` | int | 対象ユーザーの公開鍵バージョン。現行は `1`。 |
| `encryptedKeys.{uid}.nonce` | string | 予定鍵ラップ用 AES-GCM nonce。 |
| `encryptedKeys.{uid}.mac` | string | 予定鍵ラップ用 AES-GCM authentication tag。 |

`encryptedKeys.{currentUserId}` がない暗号化予定は、そのユーザーの端末では復号できない。クライアントは壊れた予定として表示せず、基本的に一覧から除外する。

### migrationEncryptedKeys

移行用公開鍵で暗号化した予定鍵。

公開先リストに公開鍵を持っていないユーザーがいる場合、またはリスト公開予定の場合に保存される。これにより、後から対象ユーザーの公開鍵が作られたときに Functions が `encryptedKeys.{uid}` を作れる。

```json
{
  "schedule-migration-v1": {
    "algorithm": "X25519+AES-GCM",
    "encryptedScheduleKey": "...",
    "ephemeralPublicKey": "...",
    "keyVersion": 1,
    "mac": "...",
    "nonce": "..."
  }
}
```

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `migrationEncryptedKeys.{keyId}` | map | 移行用鍵 ID ごとに暗号化した予定鍵。現行 keyId は `schedule-migration-v1`。 |
| `migrationEncryptedKeys.{keyId}.*` | map | 構造は `encryptedKeys.{uid}` と同じ。宛先がユーザー公開鍵ではなく移行用公開鍵になる。 |

`migrationEncryptedKeys` はユーザー端末で予定を復号するためのものではない。Functions が pending ユーザーを後から復号可能にするために使う。

### pendingEncryptedRecipientIds

公開予定だったが、作成時点で公開鍵がなかったユーザー UID の配列。

Functions は `array-contains` クエリでこのフィールドを検索し、対象ユーザーの公開鍵が作られたときに `encryptedKeys.{uid}` と `visibleTo` を更新する。

### pendingEncryptedRecipients

`pendingEncryptedRecipientIds` の詳細 map。

```json
{
  "{uid}": {
    "reason": "missingPublicKey",
    "migrationKeyId": "schedule-migration-v1",
    "sharedListIds": ["{listId}"]
  }
}
```

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `pendingEncryptedRecipients.{uid}.reason` | string | pending 理由。現行は `missingPublicKey`。 |
| `pendingEncryptedRecipients.{uid}.migrationKeyId` | string | 対応する `migrationEncryptedKeys` の keyId。 |
| `pendingEncryptedRecipients.{uid}.sharedListIds` | array<string> | このユーザーが pending になった共有リスト ID。 |

公開鍵が作られて Functions が成功すると、対象 UID は `pendingEncryptedRecipientIds` と `pendingEncryptedRecipients` から削除され、`visibleTo` と `encryptedKeys` に追加される。

## schedules/{scheduleId}/comments/{commentId}

コメントは親予定の予定鍵で本文だけを暗号化する。コメント doc には `encryptedKeys` を持たない。

### 通常フィールド

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `userId` | string | コメント投稿者 UID。 |
| `userDisplayName` | string/null | コメント作成時点の投稿者表示名。 |
| `userPhotoUrl` | string/null | コメント作成時点の投稿者アイコン URL。 |
| `createdAt` | timestamp | コメント作成日時。 |
| `updatedAt` | timestamp | コメント更新日時。 |
| `isEdited` | boolean | 編集済みかどうか。 |

### 暗号化コメント

| フィールド | 型 | 意味 |
| --- | --- | --- |
| `encrypted` | boolean | `true` の場合、本文は `encryptedContent` から復号する。 |
| `encryptedContent.algorithm` | string | コメント本文の暗号化方式。現行は `AES-GCM`。 |
| `encryptedContent.cipherText` | string | 暗号化されたコメント本文。Base64 URL エンコード。 |
| `encryptedContent.nonce` | string | AES-GCM nonce。Base64 URL エンコード。 |
| `encryptedContent.mac` | string | AES-GCM authentication tag。Base64 URL エンコード。 |

復号手順は次の通り。

1. 親予定 `schedules/{scheduleId}` を読む。
2. `encryptedKeys.{currentUserId}` から予定鍵を復号する。
3. 復号した予定鍵でコメントの `encryptedContent` を復号する。

### 後方互換

`encrypted != true` のコメントは平文の `content` を読む。

暗号化予定でも、クライアントが親予定の予定鍵を取得できない場合は、コメント本文も復号できない。この場合は UI 上で `コメントを復号できません` にフォールバックする。

## 公開先追加時の挙動

### 予定作成時

1. クライアントが予定鍵を生成する。
2. `title` / `description` / `location` を `encryptedPayload` に暗号化する。
3. クライアントは `visibleTo` に owner だけを入れる。
4. クライアントは `encryptedKeys` に owner 向けの予定鍵だけを入れる。
5. `sharedLists` がある暗号化予定では、移行用公開鍵で予定鍵を暗号化して `migrationEncryptedKeys` を保存する。
6. Functions の schedule trigger が `sharedLists` を読み、owner が所有するリストの members を公開意図として再計算する。
7. 公開鍵があるユーザーは `encryptedKeys` と `visibleTo` に追加される。
8. 公開鍵がないユーザーは `pendingEncryptedRecipientIds` と `pendingEncryptedRecipients` に入る。

クライアントから他人の UID を `visibleTo` や `encryptedKeys` に直接入れる書き込みは Security Rules で拒否する。

### ユーザーの公開鍵が後から作られた時

`users/{uid}/encryption/current` が作成・更新されると、Functions の `onUserEncryptionKeyWritten` が走る。

1. `pendingEncryptedRecipientIds` に対象 UID を含む予定を検索する。
2. `migrationEncryptedKeys.{migrationKeyId}` と Secret Manager の移行用秘密鍵で予定鍵を復号する。
3. 対象 UID の公開鍵で予定鍵を再暗号化する。
4. `encryptedKeys.{uid}` を追加する。
5. `visibleTo` に UID を追加する。
6. pending から UID を削除する。

### リストにメンバーが後から追加された時

Functions 側でリストの意図上の公開先を再計算する。

- 追加メンバーに公開鍵があり、`migrationEncryptedKeys` がある場合は `encryptedKeys.{uid}` と `visibleTo` を追加する。
- 公開鍵がない、または移行用鍵で再ラップできない場合は pending に入れる。

## 注意点

- `sharedLists` が公開意図の正で、`visibleTo` はサーバー生成の派生データ。
- `visibleTo` は「本来公開したい全員」ではなく、「現時点で復号可能な公開先」を表す。
- 本来公開したいがまだ復号できないユーザーは pending に入る。
- `sharedLists` はリスト公開の意図を残すためのフィールドで、復号可否そのものは `encryptedKeys` で決まる。
- `migrationEncryptedKeys` がない古い暗号化予定は、公開鍵がないユーザーや後から追加されたユーザーにサーバー側で予定鍵を再配布できない。
- コメントは親予定の予定鍵に依存する。親予定を復号できないユーザーはコメントも復号できない。
