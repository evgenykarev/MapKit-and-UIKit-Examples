//
//  MKAnnotationPoint.swift
//  MapPoints
//
//  Created by Evgeny Karev on 12.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

protocol MKPointAnnotationIconDelegate: class {
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didChangeIconTo icon: UIImage)
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didSave isSaved: Bool)
}

class MKPointAnnotationIcon: MKPointAnnotation {
    static var pointIcon = UIImage(named: "empty_point")!
    static var pointIconActive = UIImage(named: "active_point")!
    
    weak var delegate: MKPointAnnotationIconDelegate?
    
    var isActive: Bool {
        didSet {
            if oldValue != isActive {
                delegate?.pointAnnotationIcon(self, didChangeIconTo: self.icon)
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
        return isActive ? type(of: self).pointIconActive : type(of: self).pointIcon
    }
    
    var iconForAccessoryView: UIImage {
        return type(of: self).pointIcon
    }
    
    init(isActive: Bool) {
        self.isActive = isActive
        self._isSaved = false

        super.init()
    }
}
