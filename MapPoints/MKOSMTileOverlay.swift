//
//  MKOSMTileOverlay.swift
//  MapPoints
//
//  Created by Evgeny Karev on 16.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

class MKOSMTileOverlay: MKCachedTileOverlay {
    override class var mapName: String {
        return "OSM"
    }

    init() {
        super.init(urlTemplate: "http://c.tile.openstreetmap.org/{z}/{x}/{y}.png")
    }
}
