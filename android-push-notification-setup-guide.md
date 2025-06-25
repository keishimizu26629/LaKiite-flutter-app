# LaKiite Android プッシュ通知 設定ガイド

Android のプッシュ通知設定について、現在の状況と必要な追加設定を解説します。

## 📊 現在の Android 設定状況

### ✅ **既に設定済みの項目**

#### **1. Google Services 設定**

- ✅ `google-services.json` ファイルが環境別に配置済み
- ✅ Gradle プラグインが適用済み: `apply plugin: 'com.google.gms.google-services'`

#### **2. 権限設定 (AndroidManifest.xml)**

```xml
<!-- 適切に設定済み -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

#### **3. FCM 設定**

```xml
<!-- デフォルト通知設定も完了 -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/launcher_icon" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_icon_color" />
```

#### **4. Intent Filter 設定**

```xml
<!-- FCM用のインテントフィルター設定済み -->
<intent-filter>
    <action android:name="FLUTTER_NOTIFICATION_CLICK" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

---

## 🔍 **Firebase Console での設定確認**

### **開発環境 (lakiite-flutter-app-dev)**

- **Project ID**: `lakiite-flutter-app-dev`
- **App ID**: `1:3311967889:android:6e3182d1b0e0c49038a930`
- **Package Name**: `com.inoworl.lakiite`

### **本番環境 (lakiite-flutter-app-prod)**

- **Project ID**: `lakiite-flutter-app-prod`
- **App ID**: `1:817472600275:android:5fcab2f2e32f30de363c26`
- **Package Name**: `com.inoworl.lakiite`

---

## ⚠️ **潜在的に必要な追加設定**

### **1. SHA-1 フィンガープリントの登録**

Firebase Console で SHA-1 フィンガープリントが登録されているか確認が必要です。

#### **SHA-1 フィンガープリントの取得方法**

```bash
# デバッグキーの SHA-1 を取得
cd android
./gradlew signingReport

# または keytool を使用
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### **Firebase Console での設定**

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 該当プロジェクトを選択
3. **プロジェクトの設定** → **全般** タブ
4. **マイアプリ** セクションで Android アプリを選択
5. **SHA 証明書フィンガープリント** に SHA-1 を追加

### **2. 通知チャンネルの実装**

Android 8.0 (API level 26) 以降では通知チャンネルが必要です。
現在のコードには通知チャンネルの設定が見当たりません。

#### **通知チャンネルの実装**

```dart
// lib/infrastructure/firebase/push_notification_service.dart に追加
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// PushNotificationService クラスに追加
Future<void> _createNotificationChannel() async {
  if (Platform.isAndroid) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
```

### **3. Foreground 通知の設定**

アプリがフォアグラウンドの際の通知表示設定：

```dart
// アプリがフォアグラウンドの際の通知設定
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: true,
  badge: true,
  sound: true,
);
```

---

## 🔧 **推奨される追加実装**

### **1. pubspec.yaml に依存関係追加**

```yaml
dependencies:
  flutter_local_notifications: ^17.2.3 # 最新バージョンを使用
```

### **2. 通知チャンネル設定の実装**

```dart
// lib/infrastructure/firebase/push_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 既存の初期化コードの前に追加
    await _initializeLocalNotifications();
    await _createNotificationChannels();

    // 既存の初期化コード...
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // 一般的な通知チャンネル
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        'general_notifications',
        '一般通知',
        description: '一般的な通知を表示します',
        importance: Importance.defaultImportance,
      );

      // 重要な通知チャンネル
      const AndroidNotificationChannel importantChannel = AndroidNotificationChannel(
        'important_notifications',
        '重要な通知',
        description: '重要な通知を表示します',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      // 友達申請専用チャンネル
      const AndroidNotificationChannel friendRequestChannel = AndroidNotificationChannel(
        'friend_request_notifications',
        '友達申請',
        description: '友達申請に関する通知を表示します',
        importance: Importance.high,
      );

      // リアクション通知チャンネル
      const AndroidNotificationChannel reactionChannel = AndroidNotificationChannel(
        'reaction_notifications',
        'リアクション通知',
        description: 'リアクションに関する通知を表示します',
        importance: Importance.defaultImportance,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(importantChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(friendRequestChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(reactionChannel);
    }
  }
}
```

### **3. Cloud Functions 側での通知チャンネル指定**

```typescript
// functions/src/notification-service.ts
// 通知タイプ別にチャンネルを指定
const getNotificationChannel = (type: string): string => {
  switch (type) {
    case "friend_request":
      return "friend_request_notifications";
    case "reaction":
    case "comment":
      return "reaction_notifications";
    case "group_invitation":
      return "important_notifications";
    default:
      return "general_notifications";
  }
};

// FCM通知送信時にチャンネルを指定
const message: admin.messaging.Message = {
  token: payload.token,
  notification: {
    title: payload.notification.title,
    body: payload.notification.body,
  },
  data: payload.data,
  android: {
    notification: {
      icon: "notification_icon",
      color: "#ffa600",
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
      channelId: getNotificationChannel(payload.data.type), // チャンネルを指定
    },
  },
  // ... iOS設定
};
```

---

## 📊 **設定状況まとめ**

| 設定項目                 | 現在の状況 | 必要なアクション        |
| ------------------------ | ---------- | ----------------------- |
| Google Services 設定     | ✅ 完了    | なし                    |
| 権限設定                 | ✅ 完了    | なし                    |
| FCM 基本設定             | ✅ 完了    | なし                    |
| SHA-1 フィンガープリント | 🔍 要確認  | Firebase Console で確認 |
| 通知チャンネル           | ❌ 未実装  | コード追加が必要        |
| Foreground 通知設定      | ⚠️ 部分的  | 設定強化推奨            |

---

## 🧪 **テスト方法**

### **1. FCM トークンの取得テスト**

```dart
void testAndroidFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Android 13以上での権限確認
  final settings = await messaging.requestPermission();
  print('Android通知権限: ${settings.authorizationStatus}');

  // FCMトークンの取得
  final token = await messaging.getToken();
  print('🤖 Android FCM Token: $token');
}
```

### **2. 通知チャンネルの確認**

Android 設定アプリで以下を確認：

1. **設定** → **アプリ** → **LaKiite**
2. **通知** をタップ
3. 作成した通知チャンネルが表示されるか確認

### **3. Firebase Console からのテスト**

1. Firebase Console → **Cloud Messaging**
2. **新しいキャンペーン** → **Notifications**
3. Android アプリを選択してテスト通知を送信

---

## 🔧 **実装優先度**

### **高優先度（必須）**

1. **SHA-1 フィンガープリントの確認・登録**
2. **通知チャンネルの実装**

### **中優先度（推奨）**

3. **Foreground 通知の強化**
4. **通知カテゴリの細分化**

### **低優先度（任意）**

5. **カスタム通知音の設定**
6. **通知のバッジ管理**

---

## 📱 **結論**

**Android は基本設定は完了していますが、以下の追加設定を推奨します:**

1. **SHA-1 フィンガープリント** の Firebase Console への登録
2. **通知チャンネル** の実装（Android 8.0+対応）
3. **Foreground 通知** の設定強化

これらの設定により、より堅牢で機能的なプッシュ通知システムが構築できます！
