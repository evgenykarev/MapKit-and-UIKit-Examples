//
//  MKCachedTileOverlay.swift
//  MapPoints
//
//  Created by Evgeny Karev on 15.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit

class MKCachedTileOverlay: MKTileOverlay {
    class var mapName: String {
        return "maps"
    }
    
    static func directory(forTileOverlayPath tileOverlayPath: MKTileOverlayPath) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        
        return "\(path)/\(mapName)/\(tileOverlayPath.z)/\(tileOverlayPath.x)/"
    }

    static func file(forTileOverlayPath tileOverlayPath: MKTileOverlayPath) -> String {
        return "\(directory(forTileOverlayPath: tileOverlayPath))\(tileOverlayPath.y).png"
    }

    static func url(forTileOverlayPath tileOverlayPath: MKTileOverlayPath) -> URL {
        return URL(fileURLWithPath: file(forTileOverlayPath: tileOverlayPath))
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: type(of: self).file(forTileOverlayPath: path)) {
            return type(of: self).url(forTileOverlayPath: path)
        } else {
            return super.url(forTilePath: path)
        }
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        super.loadTile(at: path) { (data: Data?, error: Error?) in
            defer {
                result(data, error)
            }
            
            guard let tileData = data else {
                return
            }

            let fileManager = FileManager.default

            let file = type(of: self).file(forTileOverlayPath: path)

            if !fileManager.fileExists(atPath: file) {
                let directory = type(of: self).directory(forTileOverlayPath: path)

                if !fileManager.fileExists(atPath: directory) {
                    try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
                }

                fileManager.createFile(atPath: file, contents: tileData, attributes: nil)
            }
        }
    }
}
