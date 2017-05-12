//
//  CLLocationCoordinate2D.swift
//  MapPoints
//
//  Created by Evgeny Karev on 12.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

extension CLLocationCoordinate2D: CustomStringConvertible {
    
    static func floatToDegrees(_ floatValue: Double) -> String {
        let degrees = abs(floatValue.rounded(.towardZero))
        
        var degreesPart = abs(floatValue) - degrees
        
        let minutes = (degreesPart * 60).rounded(.towardZero)
        degreesPart -= minutes / 60
        
        let seconds = (degreesPart * 3600).rounded(.towardZero)
        degreesPart -= seconds / 3600
        
        let secondsDecimalPart = (degreesPart * 1000 * 3600).rounded()
     
        return "\(Int(degrees))°\(Int(minutes))'\(Int(seconds)).\(Int(secondsDecimalPart))\""
    }
    
    public var latitudeString: String {
        return "\(CLLocationCoordinate2D.floatToDegrees(latitude))\(latitude >= 0 ? "N" : "S")"
    }
    
    public var longitudeString: String {
        return "\(CLLocationCoordinate2D.floatToDegrees(longitude))\(longitude >= 0 ? "E" : "W")"
    }
    
    // ISO 6709 Annex D
    public var description: String {
        return "\(latitudeString) \(longitudeString)"
    }
}
