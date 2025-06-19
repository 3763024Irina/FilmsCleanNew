import UIKit
import Foundation
import RealmSwift
class RoundingTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum TransitionProfile {
        case show
        case dismiss  
    }
    
    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var duration: TimeInterval = 0.4
    private let animationScale: CGFloat = 0.05
    private let dimmingViewTag = 999
    
    var onCompleted: (() -> Void)?
    var onDismissed: (() -> Void)?
    
    private var smallScale: CGAffineTransform {
        CGAffineTransform(scaleX: animationScale, y: animationScale)
    }
    
    private var dimmingColor: UIColor {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return UIColor(white: 0, alpha: 0.8)
        } else {
            return UIColor(white: 0, alpha: 0.5)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transitionProfile {
        case .show:
            animateShow(using: transitionContext)
        case .dismiss:
            animateDismiss(using: transitionContext)
        }
    }
    
    private func animateShow(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = dimmingColor
        dimmingView.alpha = 0
        dimmingView.tag = dimmingViewTag
        dimmingView.isAccessibilityElement = false
        
        toView.frame = finalFrame
        toView.center = start
        toView.transform = smallScale
        toView.alpha = 0
        
        containerView.addSubview(dimmingView)
        containerView.addSubview(toView)
        
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            dimmingView.alpha = 1
            toView.center = containerView.center
            toView.transform = .identity
            toView.alpha = 1
        }
        animator.addCompletion { [weak self] position in
            let finished = position == .end
            transitionContext.completeTransition(finished)
            if finished {
                self?.onCompleted?()
            }
        }
        animator.startAnimation()
    }
    
    private func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let dimmingView = containerView.viewWithTag(dimmingViewTag)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            fromView.center = self.start
            fromView.transform = self.smallScale
            fromView.alpha = 0
            dimmingView?.alpha = 0
        }, completion: { [weak self] finished in
            if finished {
                dimmingView?.removeFromSuperview()
                fromView.removeFromSuperview()
                self?.onDismissed?()
            }
            transitionContext.completeTransition(finished)
        })
    }
}
