//
//  MapPointFirebaseManager.swift
//  MapPoints
//
//  Created by Evgeny Karev on 06.06.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import FirebaseDatabase
import GeoFire

protocol FirebaseManagerDelegate: class {
    // creating points
    func firebaseManager(_ manager: FirebaseManager, didCreate mapPoint: MapPoint, error: Error?)
    func firebaseManager(_ manager: FirebaseManager, willCreate mapPoint: MapPoint)
    
    // removing points
    func firebaseManager(_ manager: FirebaseManager, didRemove mapPoint: MapPoint, error: Error?)

    // load points from Firebase
    func firebaseManager(_ manager: FirebaseManager, didLoad mapPoint: MapPoint)
    func firebaseManager(_ manager: FirebaseManager, didRemove mapPointId: String)
}

class FirebaseManager {
    static let instance = FirebaseManager()
    
    private let refPoints: DatabaseReference
    private let refPointLocations: DatabaseReference
    private let geoFirePoints: GeoFire
    
    weak var delegate: FirebaseManagerDelegate?
    
    init() {
        Database.database().isPersistenceEnabled = true
        refPoints = Database.database().reference(withPath: "points")
        refPointLocations = Database.database().reference(withPath: "pointLocations")
        geoFirePoints = GeoFire(firebaseRef: refPointLocations)
    }
    
    func createMapPoint(for annotation: MKPointAnnotationIcon) {
        let id = refPoints.childByAutoId().key
        
        let mapPoint = MapPoint(id: id, annotation: annotation)
        
        delegate?.firebaseManager(self, willCreate: mapPoint)
        
        let point = mapPoint.firebaseDict
        
        refPoints.updateChildValues([id: point]) { (error, _) in
            guard error == nil else {
                self.delegate?.firebaseManager(self, didCreate: mapPoint, error: error)
                return
            }
        }
        
        geoFirePoints.setLocation(for: mapPoint.coordinate, for: id) { (error: Error?) in
            guard error == nil else {
                self.delegate?.firebaseManager(self, didCreate: mapPoint, error: error)
                return
            }
            
            self.delegate?.firebaseManager(self, didCreate: mapPoint, error: nil)
        }
    }

    func removeMapPoint(_ mapPoint: MapPoint) {
        refPointLocations.child(mapPoint.id).removeValue { (error: Error?, _: DatabaseReference) in
            guard error == nil else {
                self.delegate?.firebaseManager(self, didRemove: mapPoint, error: error!)

                return
            }
        }
        
        refPoints.child(mapPoint.id).removeValue(completionBlock: { (error: Error?, _: DatabaseReference) in
            // if error recieved ignore it, because point location was deleted
            self.delegate?.firebaseManager(self, didRemove: mapPoint, error: nil)
        })
    }

    private var pointsQuery: GFCircleQuery?
    
    private func setupListeners() {
        guard let query = pointsQuery else {
            return
        }
        
        query.observe(.keyEntered) { (id: String?, location: CLLocation?) in
            guard let pointId = id else {
                return
            }

            guard let pointLocation = location else {
                return
            }
            
            self.refPoints.child(pointId).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let pointDictionary = snapshot.value as? NSDictionary else {
                    print("error load \(pointId)-\(pointLocation)")
                    return
                }
                
                guard let pointTitle = pointDictionary["title"] as? String else {
                    print("error load \(pointId)-\(pointLocation)")
                    return
                }

                let mapPoint = MapPoint(id: pointId, coordinate: pointLocation.coordinate, title: pointTitle)
                
                self.delegate?.firebaseManager(self, didLoad: mapPoint)
            })
        }
        
        query.observe(.keyExited) { (id: String?, _: CLLocation?) in
            guard let pointId = id else {
                return
            }

            self.delegate?.firebaseManager(self, didRemove: pointId)
        }
    }
    
    var isListening: Bool = false {
        didSet {
            guard oldValue != isListening else {
                return
            }

            if isListening {
                setupListeners()
            } else {
                pointsQuery?.removeAllObservers()
            }
        }
    }
    
    
    func updateListening(for mapView: MKMapView) {
        let centerMap = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let mapRadius = mapView.mapRadiusMeters/1000
        let minRadius = 1.0
        let maxRadius = 100.0

        var radius = mapRadius * 10
        radius = max(radius, minRadius)
        radius = min(radius, maxRadius)

        if let query = pointsQuery {
            query.center = centerMap
            query.radius = radius
        } else {
            if isListening {
                pointsQuery = self.geoFirePoints.query(at: centerMap, withRadius: radius)
                setupListeners()
            }
        }
    }

}
