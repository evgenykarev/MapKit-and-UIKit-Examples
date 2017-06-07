//
//  GeoFire.swift
//  MapPoints
//
//  Created by Evgeny Karev on 07.06.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import CoreLocation
import GeoFire

extension GeoFire {
    open func setLocation(for coordinate: CLLocationCoordinate2D, for key: String!, with completionBlock: @escaping GFCompletionBlock) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        self.setLocation(location, forKey: key, withCompletionBlock: completionBlock)
    }

}
