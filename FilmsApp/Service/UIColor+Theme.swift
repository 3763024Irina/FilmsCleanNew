//
//  UIColor+Theme.swift
//  FilmsApp
//
//  Created by Irina on 1/7/25.
//

import Foundation
import UIKit

extension UIColor {
    /// Основная (первичная) из триады
    static var triadPrimary: UIColor {
        UIColor(named: "TriadPrimary")!
    }
    /// Вторичная из триады
    static var triadSecondary: UIColor {
        UIColor(named: "TriadSecondary")!
    }
    /// Третичная из триады
    static var triadTertiary: UIColor {
        UIColor(named: "TriadTertiary")!
    }
}
