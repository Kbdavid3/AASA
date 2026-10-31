import UIKit
import SwiftUI

class OnboardingPresenter {
    static func presentOnboarding(from viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: OnboardingCoordinatorView())
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true, completion: nil)
    }
}
