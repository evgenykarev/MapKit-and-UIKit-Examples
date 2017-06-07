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
    
    /// Length from left top point mapView to center point in meters
    var mapRadiusMeters: Double {
        let leftPoint = self.convert(CGPoint(x: self.frame.minX, y: self.frame.minY), toCoordinateFrom: self)
        let leftLocation = CLLocation(latitude: leftPoint.latitude, longitude: leftPoint.longitude)
        
        let centerPoint = self.centerCoordinate
        let centerLocation = CLLocation(latitude: centerPoint.latitude, longitude: centerPoint.longitude)
        
        return centerLocation.distance(from: leftLocation)
    }
    
    /// Zoom map by multipluer. If multipluer = 2, the area of map expands by 2 time
    func zoom(byMultiplier multiplier: Double, animated: Bool) {
        if animated {
            let newCamera: MKMapCamera
            
            if #available(iOS 9.0, *) {
                newCamera = MKMapCamera(lookingAtCenter: camera.centerCoordinate, fromDistance: camera.altitude * multiplier, pitch: camera.pitch, heading: camera.heading)
            } else {
                newCamera = MKMapCamera()
                newCamera.centerCoordinate = camera.centerCoordinate
                newCamera.heading = camera.heading
                newCamera.altitude = camera.altitude * multiplier
                newCamera.pitch = camera.pitch
            }
            
            self.setCamera(newCamera, animated: true)
        } else {
            self.camera.altitude *= multiplier
        }
    }
    
    /// Move map to offset in points
    func move(toOffsetX offsetX: CGFloat, offsetY: CGFloat, animated: Bool) {
        guard offsetX != 0 || offsetY != 0 else {
            return
        }
        
        var newCenter = convert(centerCoordinate, toPointTo: self)
        newCenter.x -= offsetX
        newCenter.y -= offsetY
        let newCenterCoordinate = convert(newCenter, toCoordinateFrom: self)
        
        // without cancel follow mode mapView refreshes map zoom state
        self.userTrackingMode = .none

        setCenter(newCenterCoordinate, animated: animated)
    }

    /// Move annotation to selected rect in the map
    /**
    - parameter annotation: The annotation placed in the map
    - parameter toRect: After action the annotation point will replace to this rect
    - parameter animated: Do this replace with animation
    */
    func moveAnnotationToRect(_ annotation: MKAnnotation, toRect: CGRect, animated: Bool) {

        let point = convert(annotation.coordinate, toPointTo: self)
        
        guard !toRect.contains(point) else {
            return
        }
        
        var offsetMapY: CGFloat = 0
        var offsetMapX: CGFloat = 0
        
        if toRect.minX - point.x > 0 {
            offsetMapX += (toRect.minX - point.x)
        }
        
        if point.x - toRect.maxX > 0 {
            offsetMapX -= point.x - toRect.maxX
        }
        
        let annotationHeight = view(for: annotation)?.frame.height ?? 0
        
        if toRect.minY + annotationHeight - point.y > 0 {
            offsetMapY += (toRect.minY + annotationHeight - point.y)
        }
        
        let underMenuHeight = point.y - toRect.maxY
        
        if underMenuHeight > 0 {
            offsetMapY -= underMenuHeight
        }
        
        move(toOffsetX: offsetMapX, offsetY: offsetMapY, animated: animated)
    }
}
