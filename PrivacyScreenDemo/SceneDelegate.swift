import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    private var privacyWindow: UIWindow?
    private weak var previousFirstResponder: UIResponder?
    
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        window = (scene as? UIWindowScene)?.windows.first(where: \.isKeyWindow)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        if PrivacyScreenSuppression.isSuppressed { return }
        showPrivacyWindow(windowScene: windowScene)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        hidePrivacyWindow()
    }
    
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
}

private extension UIView {
    func currentFirstResponder() -> UIResponder? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let responder = subview.currentFirstResponder() {
                return responder
            }
        }
        return nil
    }
}
