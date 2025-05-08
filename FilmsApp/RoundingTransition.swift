import UIKit

class RoundingTransition: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionProfile {
        case show
        case pop
    }

    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var duration: TimeInterval = 0.4

    private let animationScale: CGFloat = 0.05

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transitionProfile {
        case .show:
            animateShow(using: transitionContext)
        case .pop:
            animatePop(using: transitionContext)
        }
    }

    private func animateShow(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0
        dimmingView.tag = 999  // чтобы потом можно было удалить

        toVC.view.frame = finalFrame
        toVC.view.center = start
        toVC.view.transform = CGAffineTransform(scaleX: animationScale, y: animationScale)
        toVC.view.alpha = 0

        containerView.addSubview(dimmingView)
        containerView.addSubview(toVC.view)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            dimmingView.alpha = 1
            toVC.view.center = containerView.center
            toVC.view.transform = .identity
            toVC.view.alpha = 1
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }

    private func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }

        let containerView = transitionContext.containerView
        let dimmingView = containerView.viewWithTag(999)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            fromVC.view.center = self.start
            fromVC.view.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
            fromVC.view.alpha = 0
            dimmingView?.alpha = 0
        }, completion: { finished in
            dimmingView?.removeFromSuperview()
            fromVC.view.removeFromSuperview()
            transitionContext.completeTransition(finished)
        })
    }
}
