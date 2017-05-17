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

        let seconds = NSNumber(value: degreesPart * 3600)

        let minutesFormatter = NumberFormatter()
        minutesFormatter.minimumIntegerDigits = 2

        let secondsFormatter = NumberFormatter()
        secondsFormatter.numberStyle = .decimal
        secondsFormatter.minimumIntegerDigits = 2
        secondsFormatter.decimalSeparator = "."
        secondsFormatter.maximumFractionDigits = 3
        secondsFormatter.minimumFractionDigits = 3

        return "\(Int(degrees))°\(minutesFormatter.string(from: NSNumber(value: minutes))!)′\(secondsFormatter.string(from: seconds)!)″"
    }
    
    public var latitudeString: String {
        return "\(CLLocationCoordinate2D.floatToDegrees(latitude))\(latitude >= 0 ? "N" : "S")"
    }
    
    public var longitudeString: String {
        return "\(CLLocationCoordinate2D.floatToDegrees(longitude))\(longitude >= 0 ? "E" : "W")"
    }
    
    /// Show coordinates in human readble format
    /// ISO 6709 Annex D
    /// https://en.wikipedia.org/wiki/ISO_6709
    public var description: String {
        return "\(latitudeString) \(longitudeString)"
    }
}
