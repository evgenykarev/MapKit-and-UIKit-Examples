//
//  MKMapView.swift
//  MapPoints
//
//  Created by Evgeny Karev on 11.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

extension MKMapView {
    
    /// Length from left top point mapView to right top point in meters
    var mapWidthMeters: Double {
        let leftPoint = self.convert(CGPoint(x: self.frame.minX, y: self.frame.minY), toCoordinateFrom: self)
        let leftLocation = CLLocation(latitude: leftPoint.latitude, longitude: leftPoint.longitude)
        
        let rightPoint = self.convert(CGPoint(x: self.frame.maxX, y: self.frame.minY), toCoordinateFrom: self)
        let rightLocation = CLLocation(latitude: rightPoint.latitude, longitude: rightPoint.longitude)
        
        return rightLocation.distance(from: leftLocation)
    }
}
