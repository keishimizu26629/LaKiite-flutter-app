# ネットワークセキュリティ設定

## 概要

LaKiiteアプリでは、セキュリティ強化のためにHTTPS通信を強制し、不要なHTTP通信を制限しています。

## iOS ATS (App Transport Security) 設定

### 設定場所
`ios/Runner/Info.plist`

### 設定内容
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <false/>
</dict>
```

### 効果
- **HTTPS通信のみ許可**: すべての通信がTLS/SSL暗号化される
- **HTTP通信を禁止**: 暗号化されていない通信をブロック
- **App Store審査対応**: Appleのセキュリティ要件を満たす

## Android Network Security Config

### 設定場所
- `android/app/src/main/res/xml/network_security_config.xml`
- `android/app/src/main/AndroidManifest.xml`

### 設定内容

#### network_security_config.xml
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

#### AndroidManifest.xml
```xml
<application
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">
```

### 効果
- **クリアテキスト通信を禁止**: HTTP通信をブロック
- **HTTPS通信のみ許可**: TLS/SSL暗号化された通信のみ
- **Android 9+対応**: 最新のセキュリティ要件を満たす

## セキュリティ上の利点

### 1. 中間者攻撃の防止
- 通信内容の盗聴を防止
- データの改ざんを防止

### 2. ユーザープライバシーの保護
- 個人情報の暗号化
- 通信経路でのデータ漏洩防止

### 3. ストア審査対応
- Apple App Store審査要件を満たす
- Google Play審査要件を満たす

## 例外設定が必要な場合

### iOS (Info.plist)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Android (network_security_config.xml)
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>

    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">example.com</domain>
    </domain-config>
</network-security-config>
```

## 注意事項

1. **例外設定は最小限に**: セキュリティリスクを避けるため
2. **ストア審査**: HTTP通信の正当な理由が必要
3. **定期的な見直し**: 不要な例外設定の削除

## 現在の状況

LaKiiteプロジェクトでは：
- ✅ すべての通信がHTTPS
- ✅ HTTP通信の例外設定なし
- ✅ 最高レベルのセキュリティ設定
