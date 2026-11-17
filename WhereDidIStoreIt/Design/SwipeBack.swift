import UIKit

/// Screens in this app hide the navigation bar and draw their own back button, which makes UIKit
/// switch off the edge swipe-back gesture. This restores the standard gesture whenever there is
/// a screen to go back to (Apple HIG: don't block system gestures).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
