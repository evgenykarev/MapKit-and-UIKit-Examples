//
//  MKAnnotationPoint.swift
//  MapPoints
//
//  Created by Evgeny Karev on 12.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

protocol MKPointAnnotationIconDelegate: class {
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didChangeIconTo icon: UIImage, withCenterOffset centerOffset: CGPoint, withIconView iconView: UIImageView)
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didSave isSaved: Bool)
}

class MKPointAnnotationIcon: MKPointAnnotation {
    static var savedPointIconNotActive = UIImage(named: "empty_point")!
    static var notSavedPoint = UIImage(named: "active_point")!
    static var savedPointIconActive = UIImage(named: "saved_position_point")!

    weak var delegate: MKPointAnnotationIconDelegate?
    
    var isActive: Bool {
        didSet {
            if oldValue != isActive {
                delegate?.pointAnnotationIcon(self, didChangeIconTo: self.icon, withCenterOffset: self.centerOffset, withIconView: self.iconView)
            }
        }
    }
    
    private var _isSaved: Bool
    
    var isSaved: Bool {
        return _isSaved
    }
    
    func save() {
        self._isSaved = true

        delegate?.pointAnnotationIcon(self, didSave: true)
    }

    var icon: UIImage {
        if isSaved {
            return isActive ? type(of: self).savedPointIconActive : type(of: self).savedPointIconNotActive
        } else {
            return type(of: self).notSavedPoint
        }
    }
    
    var centerOffset: CGPoint {
        if isSaved && isActive {
            return CGPoint(x: 0, y: 0)
        }
        
        return CGPoint(x: 0, y: -icon.size.height/2)
    }
    
    private var _iconView: UIImageView
    
    var iconView: UIImageView {
        return _iconView
    }
    
    var iconForAccessoryView: UIImage {
        return type(of: self).savedPointIconNotActive
    }
    
    init(isActive: Bool) {
        self.isActive = isActive
        self._isSaved = false
        self._iconView = UIImageView(image: type(of: self).notSavedPoint)
        self._iconView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self._iconView.layer.shadowRadius = 3
        self._iconView.layer.shadowOpacity = 1
        self._iconView.isUserInteractionEnabled = true

        super.init()
    }
}
