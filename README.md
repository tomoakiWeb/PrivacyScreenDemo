# PrivacyScreenDemo

English | [日本語](README.ja.md)

A sample project that demonstrates how to protect sensitive information when an app moves to the background.

This is the sample code for the iOSDC Japan 2026 talk "Best Practices for Protecting Information and Building User Trust When Moving to the Background".

## Overview

When an app moves to the background, the OS takes a snapshot of its screen. This project shows how to prevent sensitive information from being exposed in the App Switcher.

[Apple's official documentation](https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background) asks apps to remove sensitive information from their views when moving to the background.

## Approaches

### Approach 1: Using `privacySensitive`

A SwiftUI view modifier that protects the content of the view it is applied to. When the app moves to the background, the content is masked with a gray view, as shown in the image below.

```swift
Text("1234 1234 1234 1234")
    .privacySensitive()
```

However, because it must be applied to each protected view individually, developers have to decide which information to hide. There is also a risk of forgetting to apply it when new screens are added in the future.

<img width="202"  alt="PrivacySensitive" src="https://github.com/user-attachments/assets/3f636fd3-93f1-4423-affa-f156c472ee1f" />

---

### Approach 2: Using a Full-Screen Overlay

This approach presents a UIWindow in front of the app when it becomes inactive, hiding the entire screen. Since nothing needs to be applied per view, sensitive information across the whole app is reliably protected.

#### Setup

To use a `SceneDelegate` in a SwiftUI app, set `delegateClass` in `AppDelegate`'s `application(_:configurationForConnecting:options:)`.

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

Connect the `AppDelegate` to the SwiftUI app with `@UIApplicationDelegateAdaptor`.

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

#### Showing and Hiding the Privacy Screen

`sceneWillResignActive` is called right before the app becomes inactive, such as when moving to the background or when Notification Center is shown. The privacy screen is displayed at this point.

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

`showPrivacyWindow` saves the current first responder so that TextField focus can be restored when the app returns, then dismisses the keyboard. It then creates a new `UIWindow` in the same `UIWindowScene` and brings it to the front.

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

#### Privacy Screen UI

The privacy screen is a SwiftUI view wrapped in a `UIHostingController`.

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

#### Suppressing the Privacy Screen

You may not want to show the privacy screen during operations that intentionally bring system UI to the front, such as the camera permission dialog. `PrivacyScreenSuppression` lets you suppress it only while an operation is running.

```swift
// The privacy screen is not shown while suppressed
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

#### Demo

<table>
  <tr>
    <th align="center">Normal</th>
    <th align="center">With Alert</th>
    <th align="center">With Keyboard</th>
    <th align="center">With System Alert</th>
  </tr>
  <tr>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/a11a2cea-8f54-4ecc-9019-255bf7e85714" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/3d8e02fb-da5f-4de9-ae10-86d101f12eef" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/a01d26da-47aa-4563-a577-6e96efa599b1" width="200"></td>
    <td align="center" width="25%"><video src="https://github.com/user-attachments/assets/de3ff208-ea36-4a99-ba5d-4eca93776704" width="200"></td>
  </tr>
</table>

## Summary
Protecting information when moving to the background is an important, often-overlooked part of keeping users' sensitive data safe. This project implements two approaches: a simple one using `privacySensitive`, and one that presents a UIWindow in front of the app. The former is easy to adopt but risks being missed on some views, while the latter protects the entire app uniformly. We hope you find it useful.
