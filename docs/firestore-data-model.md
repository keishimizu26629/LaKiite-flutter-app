# Firestore データ構造ドキュメント

本ドキュメントは、LaKiite アプリケーションで使用している Firestore のデータ構造を詳細に説明します。

## 目次

1. [全体概要](#全体概要)
2. [users コレクション](#users-コレクション)
3. [lists コレクション](#lists-コレクション)
4. [groups コレクション](#groups-コレクション)
5. [schedules コレクション](#schedules-コレクション)
6. [notifications コレクション](#notifications-コレクション)
7. [管理用コレクション](#管理用コレクション)
8. [インデックス](#インデックス)
9. [データ型の注意事項](#データ型の注意事項)

---

## 全体概要

LaKiite アプリケーションでは、以下のコレクション構造を使用しています：

- **users** - ユーザーの公開プロフィール情報
  - `users/{userId}/private/profile` - ユーザーの非公開プロフィール情報
- **lists** - ユーザーの共有リスト
- **groups** - グループ情報
- **schedules** - スケジュール情報
  - `schedules/{scheduleId}/reactions` - スケジュールへのリアクション
  - `schedules/{scheduleId}/comments` - スケジュールへのコメント
- **notifications** - 通知情報
- **user_update_history** - ユーザー更新履歴（管理用）
- **admin_alerts** - 管理者向けアラート（管理用）
- **batch_process_stats** - バッチ処理統計（管理用）

---

## users コレクション

### パス構造

```
users/{userId}
users/{userId}/private/profile
```

### users/{userId}（公開プロフィール）

#### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `displayName` | string | ✅ | ユーザーの表示名 |
| `searchId` | string | ✅ | 検索用ID（8桁英数字） |
| `iconUrl` | string \| null | ❌ | プロフィール画像のURL |
| `shortBio` | string \| null | ❌ | 自己紹介文 |
| `fcmToken` | string \| null | ❌ | FCMトークン（通知送信用） |

#### ドキュメントID

- Firebase Auth の `uid` を使用

#### データ例

```json
{
  "displayName": "Taro Yamada",
  "searchId": "A1B2C3D4",
  "iconUrl": "https://storage.googleapis.com/.../icon.png",
  "shortBio": "こんにちは！",
  "fcmToken": "xxxxx"
}
```

#### 主な操作

- **作成**: ユーザー登録時に `UserRepository.createUser()` で作成
- **更新**: `UserRepository.updateUser()` で更新
- **検索**: `searchId` による検索（`where('searchId', isEqualTo: searchId).limit(1)`）
- **FCMトークン更新**: `UserFcmTokenService` が `set(merge: true)` で更新

#### セキュリティルール

- **読み取り**: 認証済みユーザーであれば可
- **検索**: `limit <= 1` かつ `searchId ==` のみ許可
- **作成/更新/削除**: 本人のみ（`request.auth.uid == userId`）
- **必須項目検証**: `displayName` と `searchId`（形式チェックあり）

#### 参考コード

- `lib/infrastructure/user_repository.dart`
- `lib/domain/entity/user.dart`
- `lib/infrastructure/user_fcm_token_service.dart`

---

### users/{userId}/private/profile（非公開プロフィール）

#### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `name` | string | ✅ | ユーザー名（非公開） |
| `friends` | string[] | ✅ | 友達ユーザーIDの配列 |
| `groups` | string[] | ✅ | 所属グループIDの配列 |
| `lists` | string[] | ✅ | 共有リストIDの配列 |
| `createdAt` | timestamp | ✅ | 作成日時 |
| `fcmToken` | string \| null | ❌ | FCMトークン（現状はトップレベルに保存が主） |

#### データ例

```json
{
  "name": "Taro Yamada",
  "friends": ["uidB", "uidC"],
  "groups": ["groupId1", "groupId2"],
  "lists": ["listId1", "listId2"],
  "createdAt": {
    "_seconds": 1735689600,
    "_nanoseconds": 0
  }
}
```

#### 主な操作

- **作成**: ユーザー登録時に `UserRepository.createUser()` で作成
- **更新**: `UserRepository.updateUser()` で更新
- **友達追加**: Cloud Functions が通知受理時に自動更新

#### セキュリティルール

- **読み取り**: 本人または友達のみ
- **作成/更新/削除**: 本人のみ
- **必須項目検証**: `name`, `friends`, `groups`, `createdAt` が必須

#### 参考コード

- `lib/infrastructure/user_repository.dart:49`
- `lakiite-firebase-commons/functions/src/handlers/notification/triggers.ts`

---

## lists コレクション

### パス構造

```
lists/{listId}
```

### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `listName` | string | ✅ | リスト名 |
| `ownerId` | string | ✅ | 作成者のユーザーID |
| `memberIds` | string[] | ✅ | メンバーのユーザーID配列 |
| `createdAt` | timestamp | ✅ | 作成日時 |
| `iconUrl` | string \| null | ❌ | リストのアイコンURL |
| `description` | string \| null | ❌ | リストの説明 |

### ドキュメントID

- Firestore が自動生成

### データ例

```json
{
  "listName": "Family",
  "ownerId": "uid",
  "memberIds": ["uid", "uidB"],
  "createdAt": {
    "_seconds": 1735689600,
    "_nanoseconds": 0
  },
  "iconUrl": "https://.../icon.png",
  "description": "家族のリスト"
}
```

### 主な操作

- **作成**: `ListRepository.createList()` で作成
- **取得**: `where('ownerId', isEqualTo: ownerId)` で所有者のリスト一覧取得
- **メンバー追加/削除**: `FieldValue.arrayUnion/arrayRemove` を使用
- **更新**: `ListRepository.updateList()` で更新
- **削除**: `ListRepository.deleteList()` で削除

### セキュリティルール

- **読み取り**: 所有者またはメンバーのみ
- **作成**: 認証済みユーザーで、`ownerId == request.auth.uid`
- **更新**: 所有者のみ
- **削除**: 所有者のみ

### Cloud Functions との連携

- メンバー変更時、該当リストを参照する `schedules` の `visibleTo` を一括更新
- 参考: `lakiite-firebase-commons/functions/src/handlers/list/triggers.ts`

### 参考コード

- `lib/infrastructure/list_repository.dart`
- `lib/domain/entity/list.dart`

---

## groups コレクション

### パス構造

```
groups/{groupId}
```

### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `groupName` | string | ✅ | グループ名 |
| `ownerId` | string | ✅ | 作成者のユーザーID |
| `memberIds` | string[] | ✅ | メンバーのユーザーID配列 |
| `createdAt` | timestamp | ✅ | 作成日時 |
| `iconUrl` | string \| null | ❌ | グループのアイコンURL |

### ドキュメントID

- Firestore が自動生成

### データ例

```json
{
  "groupName": "開発チーム",
  "ownerId": "uid",
  "memberIds": ["uid", "uidB", "uidC"],
  "createdAt": {
    "_seconds": 1735689600,
    "_nanoseconds": 0
  },
  "iconUrl": "https://.../icon.png"
}
```

### 主な操作

- **作成**: `GroupRepository.createGroup()` で作成
- **取得**: `where('memberIds', arrayContains: userId)` でメンバーのグループ一覧取得
- **メンバー追加/削除**: `FieldValue.arrayUnion/arrayRemove` を使用
- **更新**: `GroupRepository.updateGroup()` で更新
- **削除**: `GroupRepository.deleteGroup()` で削除

### セキュリティルール

- **読み取り**: 認証済みユーザーであれば可
- **作成**: 認証済みユーザーで、`ownerId == request.auth.uid` かつ `memberIds` に所有者を含む
- **更新**: オーナーまたはメンバー
- **削除**: オーナーのみ

### Cloud Functions との連携

- グループ作成時、作成者の `users/{uid}/private/profile.groups` にグループIDを追加
- 参考: `lakiite-firebase-commons/functions/src/handlers/group/triggers.ts`

### 参考コード

- `lib/infrastructure/group_repository.dart`
- `lib/domain/entity/group.dart`

---

## schedules コレクション

### パス構造

```
schedules/{scheduleId}
schedules/{scheduleId}/reactions/{userId}
schedules/{scheduleId}/comments/{commentId}
```

### schedules/{scheduleId}

#### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `title` | string | ✅ | スケジュールのタイトル |
| `description` | string | ✅ | スケジュールの説明 |
| `location` | string \| null | ❌ | 場所 |
| `startDateTime` | string | ✅ | 開始日時（ISO 8601形式） |
| `endDateTime` | string | ✅ | 終了日時（ISO 8601形式） |
| `ownerId` | string | ✅ | 作成者のユーザーID |
| `ownerDisplayName` | string | ✅ | 作成者の表示名 |
| `ownerPhotoUrl` | string \| null | ❌ | 作成者のプロフィール画像URL |
| `sharedLists` | string[] | ✅ | 共有リストIDの配列 |
| `visibleTo` | string[] | ✅ | 閲覧可能なユーザーIDの配列 |
| `reactionCount` | number | ✅ | リアクション数（初期値: 0） |
| `commentCount` | number | ✅ | コメント数（初期値: 0） |
| `createdAt` | string \| timestamp | ✅ | 作成日時（ISO 8601形式またはtimestamp） |
| `updatedAt` | string \| timestamp | ✅ | 更新日時（ISO 8601形式またはtimestamp） |

#### ドキュメントID

- Firestore が自動生成

#### データ例

```json
{
  "title": "Dinner",
  "description": "With friends",
  "location": "Shibuya",
  "startDateTime": "2025-01-12T19:00:00.000",
  "endDateTime": "2025-01-12T21:00:00.000",
  "ownerId": "uid",
  "ownerDisplayName": "Taro Yamada",
  "ownerPhotoUrl": "https://.../icon.png",
  "sharedLists": ["listId"],
  "visibleTo": ["uid", "uidB"],
  "reactionCount": 1,
  "commentCount": 0,
  "createdAt": "2025-01-10T08:00:00.000",
  "updatedAt": {
    "_seconds": 1736500000,
    "_nanoseconds": 0
  }
}
```

#### 主なクエリ

1. **ユーザー向け一覧取得**（6ヶ月分）
   ```dart
   collection('schedules')
     .where('visibleTo', arrayContains: userId)
     .where('startDateTime', isGreaterThanOrEqualTo: sixMonthsAgoIso)
     .orderBy('startDateTime', ascending: true)
   ```

2. **リスト向け一覧取得**
   ```dart
   collection('schedules')
     .where('sharedLists', arrayContains: listId)
     .where('startDateTime', isGreaterThanOrEqualTo: iso)
     .orderBy('startDateTime', ascending: true)
   ```

3. **所有者のスケジュール取得**
   ```dart
   collection('schedules')
     .where('ownerId', isEqualTo: userId)
     .orderBy('startDateTime', ascending: true)
   ```

#### セキュリティルール

- **読み取り**: 所有者、`visibleTo` に含まれるユーザー、または共有リストのメンバー
- **作成**: 所有者のみ、カウンタは 0 で作成必須
- **更新**: 所有者のみ、必須項目を保持しつつ、カウンタ型は number を維持
- **削除**: 所有者のみ

#### プロフィール情報の更新について

⚠️ **重要**: `ownerDisplayName` と `ownerPhotoUrl` はスケジュール作成時に `users` コレクションからコピーされますが、ユーザーがプロフィール情報を変更しても即座には反映されません。

- **現状**: スケジュール作成時にのみ最新のプロフィール情報が設定される
- **今後の実装予定**: 日次バッチ処理でプロフィール変更を一括反映（詳細は「今後実装予定」セクション参照）

#### データ型の注意事項

⚠️ **重要**: 日時フィールドの型が混在しています

- **アプリ作成時**: ISO 8601 文字列形式（`"2025-01-12T19:00:00.000"`）
- **Cloud Functions 更新時**: `updatedAt` が `timestamp` になる可能性あり
- **読み取り**: Mapper 側で `Timestamp`/`string` の両方を許容

#### 参考コード

- `lib/infrastructure/schedule_repository.dart`
- `lib/infrastructure/mapper/schedule_mapper.dart`
- `lib/domain/entity/schedule.dart`

---

### schedules/{scheduleId}/reactions/{userId}（リアクション）

#### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `userId` | string | ✅ | ユーザーID（DocID と同一） |
| `type` | string | ✅ | リアクションタイプ（`"going"` または `"thinking"`） |
| `createdAt` | timestamp | ✅ | 作成日時 |
| `userDisplayName` | string \| null | ❌ | ユーザーの表示名（作成時に `users` からコピー） |
| `userPhotoUrl` | string \| null | ❌ | ユーザーのプロフィール画像URL（作成時に `users` からコピー） |

#### ドキュメントID

- ユーザーID（`userId`）を使用（ユーザーごとに1つのリアクションのみ）

#### データ例

```json
{
  "userId": "uidB",
  "type": "going",
  "userDisplayName": "Jiro Yamada",
  "userPhotoUrl": "https://.../iconB.png",
  "createdAt": {
    "_seconds": 1736500100,
    "_nanoseconds": 0
  }
}
```

#### リアクションタイプ

- `"going"` - 行きます！🙋
- `"thinking"` - 考え中！🤔

#### 主な操作

- **作成**: `ScheduleInteractionRepository.addReaction()` で作成
- **削除**: `ScheduleInteractionRepository.removeReaction()` で削除
- **取得**: `ScheduleInteractionRepository.getReactions()` で取得
- **監視**: `ScheduleInteractionRepository.watchReactions()` でリアルタイム監視

#### セキュリティルール

- **読み取り**: 認証済みユーザーであれば可
- **作成/更新**: DocID=自分の userId、かつ `userId` フィールド=自分
- **削除**: 自分のリアクションのみ

#### プロフィール情報の更新について

⚠️ **重要**: `userDisplayName` と `userPhotoUrl` はリアクション作成時に `users` コレクションからコピーされますが、ユーザーがプロフィール情報を変更しても即座には反映されません。

- **現状**: リアクション作成時にのみ最新のプロフィール情報が設定される
- **実装済み**: 日次バッチ処理でプロフィール変更を一括反映（`batch-sync.ts` で実装済み）

#### Cloud Functions との連携

- 追加で `reactionCount` +1、削除で -1（`updatedAt` に serverTimestamp）
- 参考: `lakiite-firebase-commons/functions/src/handlers/schedule/triggers.ts`

#### 参考コード

- `lib/infrastructure/schedule_interaction_repository.dart`
- `lib/domain/entity/schedule_reaction.dart`

---

### schedules/{scheduleId}/comments/{commentId}（コメント）

#### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `userId` | string | ✅ | 作成者のユーザーID |
| `content` | string | ✅ | コメント内容 |
| `createdAt` | timestamp | ✅ | 作成日時 |
| `updatedAt` | timestamp | ✅ | 更新日時 |
| `isEdited` | bool | ✅ | 編集済みフラグ（既定: false） |
| `userDisplayName` | string \| null | ❌ | ユーザーの表示名（作成時に `users` からコピー） |
| `userPhotoUrl` | string \| null | ❌ | ユーザーのプロフィール画像URL（作成時に `users` からコピー） |

#### ドキュメントID

- Firestore が自動生成

#### データ例

```json
{
  "userId": "uidB",
  "content": "行きます！",
  "createdAt": {
    "_seconds": 1736500200,
    "_nanoseconds": 0
  },
  "updatedAt": {
    "_seconds": 1736500200,
    "_nanoseconds": 0
  },
  "isEdited": false,
  "userDisplayName": "Jiro Yamada",
  "userPhotoUrl": "https://.../iconB.png"
}
```

#### 主な操作

- **作成**: `ScheduleInteractionRepository.addComment()` で作成
- **更新**: `ScheduleInteractionRepository.updateComment()` で更新（`content`, `updatedAt`, `isEdited` のみ）
- **削除**: `ScheduleInteractionRepository.deleteComment()` で削除
- **取得**: `ScheduleInteractionRepository.getComments()` で取得（作成日時の降順）
- **監視**: `ScheduleInteractionRepository.watchComments()` でリアルタイム監視

#### セキュリティルール

- **読み取り**: 対象スケジュールにアクセス可能なユーザー
- **作成**: 認証済み + `userId` は自分
- **更新**: 自分のコメントのみ。更新可能フィールドは `content`/`updatedAt`/`isEdited` のみ
- **削除**: 自分のコメントのみ

#### プロフィール情報の更新について

⚠️ **重要**: `userDisplayName` と `userPhotoUrl` はコメント作成時に `users` コレクションからコピーされますが、ユーザーがプロフィール情報を変更しても即座には反映されません。

- **現状**: コメント作成時にのみ最新のプロフィール情報が設定される
- **実装済み**: 日次バッチ処理でプロフィール変更を一括反映（`batch-sync.ts` で実装済み）

#### Cloud Functions との連携

- 追加で `commentCount` +1、削除で -1（`updatedAt` に serverTimestamp）
- 参考: `lakiite-firebase-commons/functions/src/handlers/schedule/triggers.ts`

#### 参考コード

- `lib/infrastructure/schedule_interaction_repository.dart`
- `lib/domain/entity/schedule_comment.dart`

---

## notifications コレクション

### パス構造

```
notifications/{notificationId}
```

### フィールド定義

| フィールド名 | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `type` | string | ✅ | 通知タイプ（`"friend"`, `"groupInvitation"`, `"reaction"`, `"comment"`） |
| `sendUserId` | string | ✅ | 送信者のユーザーID |
| `receiveUserId` | string | ✅ | 受信者のユーザーID |
| `sendUserDisplayName` | string \| null | ❌ | 送信者の表示名 |
| `receiveUserDisplayName` | string \| null | ❌ | 受信者の表示名 |
| `status` | string | ✅ | ステータス（`"pending"`, `"accepted"`, `"rejected"`） |
| `createdAt` | timestamp | ✅ | 作成日時（serverTimestamp） |
| `updatedAt` | timestamp | ✅ | 更新日時（serverTimestamp） |
| `rejectionCount` | number | ✅ | 拒否回数（既定: 0） |
| `isRead` | bool | ✅ | 既読フラグ（既定: false） |
| `groupId` | string \| null | 条件付き | グループ招待の場合に必須 |
| `relatedItemId` | string \| null | 条件付き | リアクション/コメント通知の場合に必須 |
| `interactionId` | string \| null | 条件付き | リアクション/コメント通知の場合に任意 |

### ドキュメントID

- Firestore が自動生成

### 通知タイプ

1. **`"friend"`** - 友達申請
   - `status`: `"pending"` で作成
   - `groupId`, `relatedItemId`, `interactionId`: 不要

2. **`"groupInvitation"`** - グループ招待
   - `status`: `"pending"` で作成
   - `groupId`: 必須
   - `relatedItemId`, `interactionId`: 不要

3. **`"reaction"`** - リアクション通知
   - `status`: `"accepted"` で作成（自動承認）
   - `relatedItemId`: 必須（スケジュールID）
   - `interactionId`: 任意（リアクションID）
   - `groupId`: 不要

4. **`"comment"`** - コメント通知
   - `status`: `"accepted"` で作成（自動承認）
   - `relatedItemId`: 必須（スケジュールID）
   - `interactionId`: 任意（コメントID）
   - `groupId`: 不要

### データ例

#### 友達申請

```json
{
  "type": "friend",
  "sendUserId": "uid",
  "receiveUserId": "uidB",
  "sendUserDisplayName": "Taro Yamada",
  "receiveUserDisplayName": "Jiro Yamada",
  "status": "pending",
  "createdAt": {
    "_seconds": 1736500300,
    "_nanoseconds": 0
  },
  "updatedAt": {
    "_seconds": 1736500300,
    "_nanoseconds": 0
  },
  "rejectionCount": 0,
  "isRead": false
}
```

#### グループ招待

```json
{
  "type": "groupInvitation",
  "sendUserId": "uid",
  "receiveUserId": "uidB",
  "sendUserDisplayName": "Taro Yamada",
  "status": "pending",
  "groupId": "groupId1",
  "createdAt": {
    "_seconds": 1736500400,
    "_nanoseconds": 0
  },
  "updatedAt": {
    "_seconds": 1736500400,
    "_nanoseconds": 0
  },
  "rejectionCount": 0,
  "isRead": false
}
```

#### リアクション通知

```json
{
  "type": "reaction",
  "sendUserId": "uidB",
  "receiveUserId": "uid",
  "sendUserDisplayName": "Jiro Yamada",
  "status": "accepted",
  "relatedItemId": "scheduleId1",
  "interactionId": "uidB",
  "createdAt": {
    "_seconds": 1736500500,
    "_nanoseconds": 0
  },
  "updatedAt": {
    "_seconds": 1736500500,
    "_nanoseconds": 0
  },
  "rejectionCount": 0,
  "isRead": false
}
```

### 主なクエリ

1. **受信一覧取得**
   ```dart
   collection('notifications')
     .where('receiveUserId', isEqualTo: userId)
     .orderBy('createdAt', descending: true)
   ```

2. **種別別取得**
   ```dart
   collection('notifications')
     .where('receiveUserId', isEqualTo: userId)
     .where('type', isEqualTo: 'friend')
     .orderBy('createdAt', descending: true)
   ```

3. **送信一覧取得**
   ```dart
   collection('notifications')
     .where('sendUserId', isEqualTo: userId)
     .orderBy('createdAt', descending: true)
   ```

4. **未読数取得**
   ```dart
   collection('notifications')
     .where('receiveUserId', isEqualTo: userId)
     .where('isRead', isEqualTo: false)
   ```

### セキュリティルール

- **読み取り**: 送信者 or 受信者のみ
- **作成**: 送信者のみ。`friend`/`groupInvitation` は `pending` で、`reaction`/`comment` は `accepted` で作成
- **既読更新**: 受信者のみ、`isRead`/`updatedAt` のみ更新可
- **通常更新**: 参加者のみ。主要キー（送受信者・type）は不変、`groupInvitation` は `groupId` も不変

### プロフィール情報の更新について

⚠️ **重要**: `sendUserDisplayName` と `receiveUserDisplayName` は通知作成時に `users` コレクションからコピーされますが、ユーザーがプロフィール情報を変更しても即座には反映されません。

- **現状**: 通知作成時にのみ最新のプロフィール情報が設定される
- **今後の実装予定**: 日次バッチ処理でプロフィール変更を一括反映（詳細は「今後実装予定」セクション参照）

### Cloud Functions との連携

`status` が `accepted` に変化した場合：

- **`friend`**: 双方の `users/{uid}/private/profile.friends` に相互に追加
- **`groupInvitation`**: 受信者を `groups/{groupId}.memberIds` に追加＆`users/{uid}/private/profile.groups` に追加

参考: `lakiite-firebase-commons/functions/src/handlers/notification/triggers.ts`

### 参考コード

- `lib/infrastructure/notification_repository.dart`
- `lib/domain/entity/notification.dart`

---

## 管理用コレクション

### user_update_history

#### 目的

`users` の `displayName`/`iconUrl` の変更履歴を記録

#### フィールド例

- `userId`: string
- `fieldName`: string（`"displayName"` または `"iconUrl"`）
- `oldValue`: string
- `newValue`: string
- `updatedAt`: timestamp
- `isProcessed`: bool（処理済みフラグ）
- `retryCount`: number（リトライ回数）
- `processedAt`: timestamp（処理完了日時、処理済みの場合）
- `errorMessage`: string（エラーメッセージ、リトライ時）

#### セキュリティ

- **読み取り**: 管理者のみ
- **作成**: Cloud Functions のみ（クライアントからは作成不可）
- **更新**: Cloud Functions のみ
- **削除**: 管理者のみ

#### 実装状況

⚠️ **部分実装**: 現在、以下の実装が存在しますが、完全なバッチ処理は未実装です。

- ✅ **履歴記録**: `users` コレクションの `displayName`/`iconUrl` 変更時に履歴を記録（`triggers.ts`）
- ✅ **バッチ処理の基盤**: 日次バッチ処理のスケジューラーと処理ロジックの一部が実装済み（`batch-sync.ts`）
- ⚠️ **更新対象**: 現在は `reactions` と `comments` のみを更新（`schedules` と `notifications` は未実装）

#### 参考

- `lakiite-firebase-commons/functions/src/handlers/user/triggers.ts`
- `lakiite-firebase-commons/functions/src/handlers/user/batch-sync.ts`

---

### admin_alerts

#### 目的

管理者向けアラート情報

#### セキュリティ

- **読み取り**: 管理者のみ
- **作成**: Cloud Functions のみ（クライアントからは作成不可）
- **更新**: 管理者のみ
- **削除**: 管理者のみ

---

### batch_process_stats

#### 目的

バッチ処理の統計情報

#### セキュリティ

- **読み取り**: 管理者のみ
- **作成**: Cloud Functions のみ（クライアントからは作成不可）
- **更新**: 禁止
- **削除**: 管理者のみ

---

## インデックス

主要なインデックスは `lakiite-firebase-commons/security_rules/firestore/firestore.indexes.json` に定義されています。

### schedules 関連

1. `visibleTo` (array-contains) + `startDateTime` (ASC/DESC)
2. `sharedLists` (array-contains) + `startDateTime` (ASC)
3. `ownerId` + `startDateTime` (ASC)
4. `visibleTo` (array-contains) + `ownerId` + `startDateTime` (ASC)

### notifications 関連

1. `receiveUserId` + `createdAt` (DESC)
2. `receiveUserId` + `type` + `createdAt` (DESC)
3. `sendUserId` + `createdAt` (DESC)
4. `sendUserId` + `type` + `createdAt` (DESC)
5. `receiveUserId` + `type` + `isRead`
6. `type` + `relatedItemId` + `createdAt` (DESC)
7. `receiveUserId` + `type` + `relatedItemId` + `createdAt` (DESC)

### lists 関連

1. `ownerId` + `createdAt` (DESC)
2. `memberIds` (array-contains) + `createdAt` (DESC)

### user_update_history 関連

1. `isProcessed` + `retryCount` + `updatedAt` (ASC)
2. `userId` + `updatedAt` (DESC)
3. `userId` + `fieldName` + `updatedAt` (DESC)
4. `isProcessed` + `updatedAt` (ASC)
5. `retryCount` + `updatedAt` (ASC)

---

## データ型の注意事項

### 日時フィールドの型混在

⚠️ **重要**: `schedules` コレクションの日時フィールド（`startDateTime`, `endDateTime`, `createdAt`, `updatedAt`）は型が混在しています。

- **アプリ作成時**: ISO 8601 文字列形式（`"2025-01-12T19:00:00.000"`）
- **Cloud Functions 更新時**: `updatedAt` が `timestamp` になる可能性あり
- **読み取り**: `ScheduleMapper` 側で `Timestamp`/`string` の両方を許容

将来的に型統一（timestamp 化）を検討すると運用がより安全です。

### 参考実装

```dart
// lib/infrastructure/mapper/schedule_mapper.dart
static DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
```

---

## 参考ファイル

### セキュリティルール

- `lakiite-firebase-commons/security_rules/firestore/firestore.rules`

### インデックス定義

- `lakiite-firebase-commons/security_rules/firestore/firestore.indexes.json`

### Cloud Functions

- `lakiite-firebase-commons/functions/src/**/*`

### Flutter アプリ実装

- **Users**: `lib/infrastructure/user_repository.dart`
- **Lists**: `lib/infrastructure/list_repository.dart`
- **Groups**: `lib/infrastructure/group_repository.dart`
- **Schedules**: `lib/infrastructure/schedule_repository.dart`
- **Reactions/Comments**: `lib/infrastructure/schedule_interaction_repository.dart`
- **Notifications**: `lib/infrastructure/notification_repository.dart`

### エンティティ定義

- **Users**: `lib/domain/entity/user.dart`, `lib/domain/entity/user_profile.dart`
- **Lists**: `lib/domain/entity/list.dart`
- **Groups**: `lib/domain/entity/group.dart`
- **Schedules**: `lib/domain/entity/schedule.dart`
- **Reactions**: `lib/domain/entity/schedule_reaction.dart`
- **Comments**: `lib/domain/entity/schedule_comment.dart`
- **Notifications**: `lib/domain/entity/notification.dart`

---

## 今後実装予定

### プロフィール情報のバッチ更新処理

#### 背景

現状、ユーザーのプロフィール情報（`displayName`, `iconUrl`）を変更した際、以下のデータに即座に反映させていません：

1. **schedules/{scheduleId}** - `ownerDisplayName`, `ownerPhotoUrl`
2. **schedules/{scheduleId}/reactions/{userId}** - `userDisplayName`, `userPhotoUrl`
3. **schedules/{scheduleId}/comments/{commentId}** - `userDisplayName`, `userPhotoUrl`
4. **notifications/{notificationId}** - `sendUserDisplayName`, `receiveUserDisplayName`

#### 実装方針

プロフィール情報を変更した際、以下の流れで処理します：

1. **変更履歴の記録**: `users` コレクションの変更を検知し、`user_update_history` に履歴を記録
2. **日次バッチ処理**: 毎日午前2時（JST）に未処理の履歴を一括処理
3. **重複実行の防止**: `isProcessed` フラグと `retryCount` で処理済み/未処理を判定

#### 更新対象データ

以下のコレクション/サブコレクションのデータを更新する必要があります：

| コレクション/パス | 更新フィールド | 実装状況 |
|-----------------|--------------|---------|
| `schedules/{scheduleId}` | `ownerDisplayName`, `ownerPhotoUrl` | ⚠️ 未実装 |
| `schedules/{scheduleId}/reactions/{userId}` | `userDisplayName`, `userPhotoUrl` | ✅ 実装済み |
| `schedules/{scheduleId}/comments/{commentId}` | `userDisplayName`, `userPhotoUrl` | ✅ 実装済み |
| `notifications/{notificationId}` | `sendUserDisplayName`, `receiveUserDisplayName` | ⚠️ 未実装 |

#### 実装時の注意事項

1. **処理済み判定**: `isProcessed == false` かつ `retryCount < 3` のレコードのみ処理
2. **最新値の取得**: 同一ユーザー・同一フィールドの複数履歴がある場合、最新の `newValue` を使用
3. **バッチ処理の制限**: Firestore のバッチ制限（500操作/バッチ）を考慮
4. **エラーハンドリング**: エラー発生時は `retryCount` を増加させ、3回以上はスキップ
5. **パフォーマンス**: 大量データの更新時は並列処理とバッチサイズの最適化が必要

#### 実装予定の処理フロー

```
1. users/{userId} の displayName/iconUrl が変更される
   ↓
2. triggers.ts が変更を検知し、user_update_history に履歴を記録
   - isProcessed: false
   - retryCount: 0
   ↓
3. 日次バッチ処理（毎日午前2時 JST）
   ↓
4. 未処理の履歴を取得（isProcessed == false && retryCount < 3）
   ↓
5. ユーザーIDごとにグループ化
   ↓
6. 各ユーザーの最新更新情報を取得
   ↓
7. 以下のデータを一括更新：
   - schedules/{scheduleId} (ownerDisplayName, ownerPhotoUrl)
   - schedules/{scheduleId}/reactions/{userId} (userDisplayName, userPhotoUrl)
   - schedules/{scheduleId}/comments/{commentId} (userDisplayName, userPhotoUrl)
   - notifications/{notificationId} (sendUserDisplayName, receiveUserDisplayName)
   ↓
8. 処理完了後、isProcessed: true にマーク
```

#### 参考実装

- **履歴記録**: `lakiite-firebase-commons/functions/src/handlers/user/triggers.ts`
- **バッチ処理（部分実装）**: `lakiite-firebase-commons/functions/src/handlers/user/batch-sync.ts`

---

## 改善提案

1. **schedules の日時フィールドを timestamp に統一**（型混在の解消）
2. **Reaction 周辺の `userPhotoUrl` キー名の統一**（`iconUrl` に寄せる）
3. **Cloud Functions の `creatorId` 参照箇所を現行 `ownerId` に合わせて棚卸し**
4. **プロフィール情報のバッチ更新処理の完全実装**（上記「今後実装予定」参照）

---

最終更新: 2025年1月
