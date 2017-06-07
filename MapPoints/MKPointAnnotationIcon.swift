//
//  MKAnnotationPoint.swift
//  MapPoints
//
//  Created by Evgeny Karev on 12.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

protocol MKPointAnnotationIconDelegate: class {
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didChangeIconTo icon: UIImage, withCenterOffset centerOffset: CGPoint)
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
                delegate?.pointAnnotationIcon(self, didChangeIconTo: self.icon, withCenterOffset: self.centerOffset)
            }
        }
    }
    
    private var _isSaved: Bool
    
    var isSaved: Bool {
        return _isSaved
    }
    
    func save() {
        guard !_isSaved else {
            return
        }
        
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
    
    var iconForAccessoryView: UIImage {
        return type(of: self).savedPointIconNotActive
    }
    
    init(isActive: Bool, isSaved: Bool) {
        self.isActive = isActive
        self._isSaved = isSaved

        super.init()
    }

}
