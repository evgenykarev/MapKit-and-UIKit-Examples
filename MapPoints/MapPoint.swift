//
//  point.swift
//  MapPoints
//
//  Created by Evgeny Karev on 06.06.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import Foundation
import CoreLocation

class MapPoint: NSObject {
    let id: String
    let coordinate: CLLocationCoordinate2D
    var title: String
    
    var subtitle: String {
        return coordinate.description
    }
    
    let annotation: MKPointAnnotationIcon
    
    init(id: String, coordinate: CLLocationCoordinate2D, title: String) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        
        annotation = MKPointAnnotationIcon(isActive: false, isSaved: true)
        annotation.title = self.title
        annotation.subtitle = coordinate.description
        annotation.coordinate = self.coordinate
    }
    
    init(id: String, annotation: MKPointAnnotationIcon) {
        self.id = id
        self.annotation = annotation

        self.coordinate = self.annotation.coordinate
        self.title = self.annotation.title ?? "unknown"
    }
    
    var firebaseDict: Dictionary<String, Any> {
        return [
            "title": title,
            "description": description
        ]
    }
}
