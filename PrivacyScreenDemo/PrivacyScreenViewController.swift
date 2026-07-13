import SwiftUI
import UIKit

final class PrivacyScreenViewController: UIHostingController<PrivacyScreenView> {
    init() {
        super.init(rootView: PrivacyScreenView())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
