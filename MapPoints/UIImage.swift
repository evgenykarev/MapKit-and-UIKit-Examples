//
//  UIImage.swift
//  MapPoints
//
//  Created by Evgeny Karev on 01.06.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import UIKit

extension UIImage {
    /// return UIImage snapshot from view
    class func image(from view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0)
        defer { UIGraphicsEndImageContext() }

        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
