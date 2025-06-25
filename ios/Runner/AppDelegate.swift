import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // テスト時は通知許可をリクエストしない
    let isTestMode = ProcessInfo.processInfo.environment["TEST_MODE"] == "true"
    if isTestMode {
      print("🧪 テスト時のため通知許可のリクエストをスキップします")
    } else {
      // プッシュ通知用の設定
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { granted, error in
            print("通知許可ステータス: \(granted), エラー: \(String(describing: error))")
            if !granted {
              print("⚠️ プッシュ通知の許可が拒否されました")
            } else {
              print("✅ プッシュ通知の許可が得られました")
            }
          }
        )
      } else {
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
      }

      application.registerForRemoteNotifications()
    }

    Messaging.messaging().delegate = self

    // 起動オプションに通知が含まれている場合をログ出力
    if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] {
      print("🚀 アプリ起動時に通知を受信: \(notification)")
    }

    // 現在の通知設定を確認
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("📱 現在の通知設定:")
      print("   - authorizationStatus: \(settings.authorizationStatus.rawValue)")
      print("   - alertSetting: \(settings.alertSetting.rawValue)")
      print("   - badgeSetting: \(settings.badgeSetting.rawValue)")
      print("   - soundSetting: \(settings.soundSetting.rawValue)")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // リモート通知の登録成功時
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // APNsトークンをFirebaseに設定
    Messaging.messaging().apnsToken = deviceToken
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNsデバイストークン登録成功: \(tokenString)")

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // リモート通知の登録失敗時
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ リモート通知の登録に失敗: \(error.localizedDescription)")
    print("❌ エラー詳細: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // リモート通知を受信した場合（バックグラウンド・フォアグラウンド共通）
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    print("📨 リモート通知を受信: \(userInfo)")
    print("📨 アプリ状態: \(application.applicationState.rawValue)")
    super.application(application, didReceiveRemoteNotification: userInfo)
  }

  // リモート通知を受信した場合（バックグラウンド処理対応）
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📨 リモート通知を受信（バックグラウンド対応）: \(userInfo)")
    print("📨 アプリ状態: \(application.applicationState.rawValue)")

    // Firebaseに通知を処理させる
    if let messageID = userInfo["gcm.message_id"] {
      print("📨 Firebase Message ID: \(messageID)")
    }

    // 通知の内容を詳細にログ出力
    if let aps = userInfo["aps"] as? [String: Any] {
      print("📨 APS情報: \(aps)")
      if let alert = aps["alert"] {
        print("📨 アラート内容: \(alert)")
      }
      if let badge = aps["badge"] {
        print("📨 バッジ数: \(badge)")
      }
      if let sound = aps["sound"] {
        print("📨 サウンド: \(sound)")
      }
    }

    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    completionHandler(.newData)
  }

  // フォアグラウンドで通知を受信した場合
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📱 フォアグラウンドで通知受信: \(userInfo)")

    // フォアグラウンドでも通知を表示
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // 通知をタップした場合
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("👆 通知タップ: \(userInfo)")

    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    print("🔑 FCMトークン受信: \(String(describing: fcmToken))")
  }
}
