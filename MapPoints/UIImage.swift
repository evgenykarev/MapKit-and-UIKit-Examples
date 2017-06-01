//
//  UIImage.swift
//  MapPoints
//
//  Created by Evgeny Karev on 01.06.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import UIKit

extension UIImage {
    /// Return UIImage snapshot from view
    /**
    - parameter from: View from which it will be taken snapshot
    - returns: UIImage snapshot
    */
    class func image(from view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0)
        defer { UIGraphicsEndImageContext() }

        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
