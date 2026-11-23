# PrivacyScreenDemo

[English](README.md) | 日本語

バックグラウンド遷移時の情報保護を実装したサンプルプロジェクトです。

iOSDC Japan 2026「バックグラウンド遷移時の情報保護と安心感を高めるベストプラクティス」のサンプルコードです。

## 概要

アプリがバックグラウンドに遷移する際、OSはアプリのスクリーンショットを保存します。アプリスイッチャーで機密情報が表示されるリスクを防ぐための実装を紹介しています。

[Apple公式ドキュメント](https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background)では、バックグラウンド移行時に機密情報をビューから削除することが求められています。

## 実装方針

### 方針1: `privacySensitive` を使った実装

SwiftUI のビューモディファイアで、そのビューに含まれる内容を保護します。バックグラウンドにアプリが遷移時に画像のようにグレー色のViewでマスクされます。

```swift
Text("1234 1234 1234 1234")
    .privacySensitive()
```

ただし、保護対象のビューに個別で付与する必要があるため、どの情報を隠すかを開発者が選定しなければなりません。また、将来的に新規画面を追加した際に付与漏れが発生するリスクがあります。

<img width="239" height="115" alt="PrivacySensitive" src="https://github.com/user-attachments/assets/ff495bc4-1cc3-4c5b-b48b-69ea7d830f03" />


---

### 方針2: 全画面オーバーレイを使った実装

アプリが非アクティブになるタイミングで UIWindow を前面に表示し、画面全体を隠す方法です。付与漏れが発生しないため、アプリ全体の機密情報を確実に保護できます。

#### セットアップ

SwiftUI アプリで `SceneDelegate` を使うには、`AppDelegate` の `application(_:configurationForConnecting:options:)` で `delegateClass` を指定します。

```swift
// AppDelegate.swift
func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
}
```

`@UIApplicationDelegateAdaptor` で `AppDelegate` を SwiftUI アプリに接続します。

```swift
// PrivacyScreenDemoApp.swift
@main
struct PrivacyScreenDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### プライバシー画面の表示・非表示

`sceneWillResignActive` はバックグラウンド移行・通知センター表示など、アプリが「非アクティブ」になる直前に呼ばれます。このタイミングでプライバシー画面を表示します。

```swift
// SceneDelegate.swift
func sceneWillResignActive(_ scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    if PrivacyScreenSuppression.isSuppressed { return }
    showPrivacyWindow(windowScene: windowScene)
}

func sceneDidBecomeActive(_ scene: UIScene) {
    hidePrivacyWindow()
}
```

`showPrivacyWindow` では、復帰後に TextField のフォーカスを戻せるよう現在のファーストレスポンダーを保存してからキーボードを閉じます。その後、同じ `UIWindowScene` に新しい `UIWindow` を作成して前面に表示します。

```swift
private func showPrivacyWindow(windowScene: UIWindowScene) {
    guard privacyWindow == nil else { return }
    previousFirstResponder = window?.currentFirstResponder()
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    let newWindow = UIWindow(windowScene: windowScene)
    newWindow.rootViewController = PrivacyScreenViewController()
    newWindow.isHidden = false
    privacyWindow = newWindow
}

private func hidePrivacyWindow() {
    privacyWindow?.isHidden = true
    privacyWindow = nil
    previousFirstResponder?.becomeFirstResponder()
    previousFirstResponder = nil
}
```

#### プライバシー画面の UI

プライバシー画面は SwiftUI の View を `UIHostingController` でラップして表示します。

```swift
// PrivacyScreenView.swift
struct PrivacyScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
        }
    }
}
```

```swift
// PrivacyScreenViewController.swift
final class PrivacyScreenViewController: UIHostingController<PrivacyScreenView> {
    init() {
        super.init(rootView: PrivacyScreenView())
    }
}
```

#### プライバシー画面の抑制

カメラ許可ダイアログなど、意図的にシステム UI を前面に表示する操作中はプライバシー画面を表示したくない場合があります。`PrivacyScreenSuppression` を使うと、処理の実行中だけ抑制できます。

```swift
// 抑制中はプライバシー画面が表示されない
await PrivacyScreenSuppression.suppress {
    await requestCameraPermission()
}
```

```swift
// PrivacyScreenSuppression.swift
@MainActor
enum PrivacyScreenSuppression {
    private(set) static var isSuppressed = false

    static func suppress<T>(during operation: () async throws -> T) async rethrows -> T {
        isSuppressed = true
        defer { isSuppressed = false }
        return try await operation()
    }
}
```

#### 動作確認

<table>
  <tr>
    <th align="center">通常時</th>
    <th align="center">Alertを表示時</th>
    <th align="center">キーボード表示時</th>
    <th align="center">システムアラート表示時</th>
  </tr>
  <tr>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/33bc458a-0580-48f5-ae44-eadc02f54a7a" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/21a94b4c-b4b6-494f-a0e1-9eabf40c3ece" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/cab5def1-5fc1-4b5e-bf71-26df9a822797" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/7c605abd-fe3e-4af8-a79c-64b1cf2f9ca1" width="200"></td>
  </tr>
</table>


## まとめ
バックグラウンド遷移時の情報保護は、ユーザーの機密情報を守るうえで見落とされがちな重要な実装です。本プロジェクトでは `privacySensitive` を用いたシンプルな実装と、アプリ最前面に UIWindow を表示する方法の2つの方針を実装しました。前者は手軽に導入できる一方で付与漏れのリスクがあり、後者はアプリ全体を一律に保護できます。ぜひ参考にしてみてください。
