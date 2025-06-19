//
//  RoundingTransitionDelegate.swift
//  FilmsApp
//
//  Created by Irina on 16/6/25.
//

import Foundation
import UIKit

class RoundingTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var startPoint: CGPoint = .zero

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = RoundingTransition()
        transition.transitionProfile = .show
        transition.start = startPoint
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = RoundingTransition()
        transition.transitionProfile = .dismiss
        transition.start = startPoint
        return transition
    }
}
