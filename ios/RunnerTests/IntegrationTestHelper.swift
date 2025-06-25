import XCTest

/// 統合テスト用のヘルパークラス
/// 通知許可ダイアログの自動処理を行います
class IntegrationTestHelper: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()

        // 通知許可ダイアログの自動タップハンドラーを設定
        addUIInterruptionMonitor(withDescription: "Push Notifications") { alert in
            print("🔔 通知許可ダイアログを検出しました")

            // 日本語と英語の「許可」ボタンを探す
            let allowButtons = [
                alert.buttons["許可"],
                alert.buttons["Allow"],
                alert.buttons["OK"],
                alert.buttons["はい"]
            ]

            for allowButton in allowButtons {
                if allowButton.exists {
                    print("✅ 許可ボタンをタップします: \(allowButton.label)")
                    allowButton.tap()
                    return true
                }
            }

            print("⚠️ 許可ボタンが見つかりませんでした")
            return false
        }

        // その他の権限ダイアログも処理
        addUIInterruptionMonitor(withDescription: "Camera Permission") { alert in
            print("📸 カメラ権限ダイアログを検出しました")

            let allowButtons = [
                alert.buttons["許可"],
                alert.buttons["Allow"],
                alert.buttons["OK"]
            ]

            for allowButton in allowButtons {
                if allowButton.exists {
                    print("✅ カメラ許可ボタンをタップします")
                    allowButton.tap()
                    return true
                }
            }

            return false
        }

        addUIInterruptionMonitor(withDescription: "Photos Permission") { alert in
            print("🖼️ 写真権限ダイアログを検出しました")

            let allowButtons = [
                alert.buttons["許可"],
                alert.buttons["Allow"],
                alert.buttons["OK"]
            ]

            for allowButton in allowButtons {
                if allowButton.exists {
                    print("✅ 写真許可ボタンをタップします")
                    allowButton.tap()
                    return true
                }
            }

            return false
        }

        app.launch()

        // モニターを発火させるため1回タップ
        app.tap()
    }
}
