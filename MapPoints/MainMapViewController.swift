//
//  ViewController.swift
//  MapPoints
//
//  Created by Evgeny Karev on 27.04.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import UIKit
import MapKit


class MainMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, MKPointAnnotationIconDelegate {
    
    enum MapMode {
        case follow
        case followWithHeading
        case free
    }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var compassLabel: UILabel!
    @IBOutlet weak var scaleLabel: UILabel!

    @IBOutlet weak var addPointButton: UIButton!
    @IBOutlet weak var removePointButton: UIButton!
    @IBOutlet weak var toPointLabel: UILabel!
    @IBOutlet weak var toPointRouteButton: UIButton!
    @IBOutlet weak var removePointRouteButton: UIButton!
    @IBOutlet weak var closePointButton: UIButton!

    @IBOutlet weak var userTrackingModeButton: UIButton!

    @IBOutlet weak var bottomMenu: UIView!
    @IBOutlet weak var bottomMenuHeight: NSLayoutConstraint!

    // Local variables
    private var locationManager: CLLocationManager!

    private var currentLocation: CLLocation?
    
    private var mapMode = MapMode.free {
        didSet {
            switch mapMode {
            case .follow:
                mapView.setUserTrackingMode(.follow, animated: true)
                userTrackingModeButton.setTitle("V", for: .normal)
            case .followWithHeading:
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
                userTrackingModeButton.setTitle("|", for: .normal)

                locationManager.stopUpdatingHeading()
                userLocationHeadingSubviewRotate(to: 0)
            default:
                mapView.setUserTrackingMode(.none, animated: false)
                userTrackingModeButton.setTitle("X", for: .normal)
            }
            
            if oldValue == .followWithHeading {
                locationManager.startUpdatingHeading()
            }
        }
    }
    
    private var toPointName: String? {
        didSet {
            if let locationName = toPointName {
                toPointLabel.text = locationName
            } else {
                toPointLabel.text = "..."
            }
        }
    }
    
    private var currentAnnotation: MKPointAnnotationIcon? {
        didSet {
            guard oldValue != currentAnnotation else {
                return
            }
            
            oldValue?.isActive = false
            
            if let annotationForRemove = annotationForAdding, annotationForRemove != currentAnnotation {
                mapView.removeAnnotation(annotationForRemove)

                annotationForAdding = nil
            }

            if currentAnnotation == nil {
                annotationForUpdating = nil
                annotationForAdding = nil
                
                menuState = .withoutActivePoint(height: MenuState.menuHeightCollapsed, dragged: false)
            } else {
                let activePointState: MenuState.ActivePointState = annotationForAdding != nil ? .forAdding : .forUpdating
                
                menuState = .withActivePoint(height: MenuState.menuHeightExpanded, dragged: false, activePointState: activePointState)
            }

            if currentAnnotation != nil {
                currentAnnotation!.isActive = true
                
                if currentAnnotation != annotationForUpdating {
                    annotationForUpdating = nil
                }
            }
        }
    }
    
    private var annotationForAdding: MKPointAnnotationIcon? {
        didSet {
            if annotationForAdding != nil {
                currentAnnotation = annotationForAdding
            }
        }
    }
    
    private var annotationForUpdating: MKPointAnnotationIcon? {
        didSet {
            if oldValue != nil && oldValue != annotationForUpdating {
                mapView.deselectAnnotation(oldValue, animated: true)
            }
            
            if annotationForUpdating != nil {
                currentAnnotation = annotationForUpdating

                findLocationName(location: CLLocation(latitude: annotationForUpdating!.coordinate.latitude, longitude: annotationForUpdating!.coordinate.longitude))
            }
        }
    }
    
    enum MapLayer {
        case initially
        case mapApple
        case satelliteApple
        case mapOSM
    }
    
    private var OSMLayer = MKOSMTileOverlay()
    
    private var mapLayer: MapLayer = MapLayer.initially {
        didSet {
            guard mapLayer != oldValue else {
                return
            }
            
            switch mapLayer {
            case .mapApple:
                mapView.mapType = .standard
                mapView.remove(OSMLayer)
                UIApplication.shared.setStatusBarStyle(.default, animated: false)
            case .satelliteApple:
                mapView.mapType = .hybrid
                mapView.remove(OSMLayer)
                UIApplication.shared.setStatusBarStyle(.lightContent, animated: false)
            case .mapOSM:
                OSMLayer.canReplaceMapContent = true
                mapView.insert(OSMLayer, at: 0)
                UIApplication.shared.setStatusBarStyle(.default, animated: false)
            default:
                mapView.mapType = .hybrid
            }
        }
    }

    @IBAction func addPointButtonTouchUpInside(_ sender: UIButton) {
        guard let annotation = annotationForAdding else {
            return
        }

        annotation.save()
        annotationForUpdating = annotation
        annotationForAdding = nil
        currentAnnotation = nil
    }
    
    @IBAction func removePointButtonTouchUpInside(_ sender: UIButton) {
        guard let annotation = annotationForUpdating else {
            return
        }

        currentAnnotation = nil
        mapView.removeAnnotation(annotation)
    }
    
    @IBAction func closePointButtonTouchUpInside(_ sender: UIButton) {
        currentAnnotation = nil
    }

    @IBAction func toPointRouteButtonTouchUpInside(_ sender: UIButton) {
        guard let sourceCoordinate = currentLocation?.coordinate else {
            return
        }
        
        guard let destinationCoordinate = currentAnnotation?.coordinate else {
            return
        }

        mapView.removeOverlays(mapView.overlays.filter({ $0 is MKPolyline }))

        let request: MKDirectionsRequest = MKDirectionsRequest()

        request.source =  MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))

        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate() { (response: MKDirectionsResponse?, error: Error?) in
            guard error == nil else {
                return
            }
            
            if let routes = response?.routes {
                guard routes.count > 0 else {
                    return
                }
                
                var visibleMapRectForAllRoutes: MKMapRect! = self.mapView.visibleMapRect
                
                for route in routes {
                    self.mapView.add(route.polyline)

                    if visibleMapRectForAllRoutes == nil {
                        visibleMapRectForAllRoutes = route.polyline.boundingMapRect
                    } else {
                        visibleMapRectForAllRoutes = MKMapRectUnion(visibleMapRectForAllRoutes, route.polyline.boundingMapRect)
                    }
                }

                self.mapView.setVisibleMapRect(visibleMapRectForAllRoutes, edgePadding: UIEdgeInsetsMake(10, 10, 10, 10), animated: true)
                
                // add point if needed
                if self.annotationForAdding != nil {
                    self.addPointButtonTouchUpInside(self.addPointButton)
                }
                
                // show remove mutton
                self.removePointRouteButton.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.removePointRouteButton.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        }
    }

    @IBAction func removePointRouteButtonTouchUpInside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        }, completion: { (_: Bool) -> Void in
            self.mapView.removeOverlays(self.mapView.overlays.filter({ $0 is MKPolyline }))
            sender.isHidden = true
        })
    }

    @IBAction func userTrackingModeButtonTouchUpInside(_ sender: UIButton) {
        switch mapMode {
        case .followWithHeading:
            mapMode = .free
        case .follow:
            mapMode = .followWithHeading
        default:
            mapMode = .follow
        }
    }

    @IBAction func mapLayerButtonTouchUpInside(_ sender: UIButton) {
        switch mapLayer {
        case .satelliteApple:
            mapLayer = .mapApple
        case .mapApple:
            mapLayer = .mapOSM
        case .mapOSM:
            mapLayer = .satelliteApple
        default:
            mapLayer = .satelliteApple
        }
    }

    private var zoomTimer: Timer?
    private var multiplierZoomTimer = 1.0
    
    func zoomTimerFire(_ timer: Timer) {
        mapView.zoom(byMultiplier: multiplierZoomTimer, animated: false)
    }

    @IBAction func zoomTapped(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let button = sender.view as? UIButton else {
                return
            }
            
            zoomTimer = Timer.scheduledTimer(timeInterval: 1/50, target: self, selector: #selector(zoomTimerFire(_:)), userInfo: nil, repeats: true)
            
            switch button.tag {
            case 1:
                multiplierZoomTimer = 1.05
            case 2:
                multiplierZoomTimer = 0.95
            default:
                break
            }
        case .ended, .cancelled, .failed:
            zoomTimer?.invalidate()
        default:
            break
        }
    }
    
    // button zoom has 2 big problem
    // 1 - when userTrackingMode.follow. http://stackoverflow.com/questions/44025756/ios-mkmapview-programmatically-zoom-via-setregion-has-bugs-when-usertrackingmode
    // 2 - when map is animating now, zoom work from point where animate was started
    @IBAction func zoomButtonTouchUpInside(_ sender: UIButton) {
        if sender.tag == 1 {
            mapView.zoom(byMultiplier: 2, animated: true)
        } else if sender.tag == 2 {
            mapView.zoom(byMultiplier: 0.5, animated: true)
        }
    }
    
    // MARK: - UIViewController
    
    private func findLocationName(location: CLLocation) {
        toPointName = nil
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks: [CLPlacemark]?, error: Error?) in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            
            if let placemark = placemarks?[0] {
                self.toPointName = placemark.address
            }
        }
    }
    
    private var countPoints = 0
    
    /// Check that menu does not close point after extending, and point not near screen edge
    private func moveAnnotationToVisibleRect(_ annotation: MKAnnotation) {
        let minOffset: CGFloat = 48
        
        let visibleRect = CGRect(x: minOffset, y: minOffset, width: mapView.frame.width - minOffset * 2, height: mapView.frame.height - minOffset * 2 - CGFloat(MenuState.menuHeightExpanded))
        
        mapView.moveAnnotationToRect(annotation, toRect: visibleRect, animated: true)
    }
    
    @IBAction func mapTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let pointCoordinate = mapView.convert(point, toCoordinateFrom: view)
        
        // update annotation
        if annotationForAdding == nil {
            annotationForAdding = MKPointAnnotationIcon(isActive: true)
            annotationForAdding!.title = "Point \(countPoints)"
            countPoints += 1
            annotationForAdding!.subtitle = "\(pointCoordinate)"
            annotationForAdding!.delegate = self
            mapView.addAnnotation(annotationForAdding!)
        }
        
        annotationForAdding!.coordinate = pointCoordinate
        
        moveAnnotationToVisibleRect(annotationForAdding!)
        
        findLocationName(location: CLLocation(latitude: pointCoordinate.latitude, longitude: pointCoordinate.longitude))

        return
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        mapLayer = .satelliteApple

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        menuState = .initialize

        removePointRouteButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        removePointRouteButton.isHidden = true

        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
        }
    }

    // TODO: remove it. It's bugfix for iOS 8
    // bug - http://stackoverflow.com/questions/43802544/viewcontroller-created-in-xcode-8-3-2-does-not-find-its-xib-file-when-project-ru
    override var nibName: String? {
        return "MainMapViewController"
    }
    
    // MARK: - MKMapViewDelegate
    
    func annotationTapped(_ sender: UIGestureRecognizer) {
        guard let annotationView = sender.view as? MKAnnotationView else {
            return
        }
        
        guard let annotation = annotationView.annotation as? MKPointAnnotationIcon else {
            return
        }
        
        guard annotation != annotationForAdding else {
            return
        }

        moveAnnotationToVisibleRect(annotation)
    }
    
    private let reusableAnnotationIdentifier = "mapPointsAnnotation"
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotationIcon = annotation as? MKPointAnnotationIcon else {
            return nil
        }

        var annotationView: MKAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: reusableAnnotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotationIcon, reuseIdentifier: reusableAnnotationIdentifier)
        }

        annotationView!.canShowCallout = annotationIcon.isSaved
        
        annotationView!.image = annotationIcon.icon
        annotationView!.centerOffset = CGPoint(x: 0, y: -annotationIcon.icon.size.height/2)
        annotationView!.leftCalloutAccessoryView = UIImageView(image: annotationIcon.iconForAccessoryView)
        
        return annotationView
    }

    private let userLocationHeadingSubview = UIImageView(image: UIImage(named: "heading"))
    
    // 0 = North
    private func userLocationHeadingSubviewRotate(to angle: Double) {
        let transformForHeading = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi / 180))
        let transformForLable = CGAffineTransform(rotationAngle: CGFloat((angle - 180) * Double.pi / 180))
        
        UIView.animate(withDuration: 0.1) {
            self.userLocationHeadingSubview.transform = transformForHeading
            self.compassLabel.transform = transformForLable
        }
    }
    
    private func userLocationHeadingSubviewRotate(to heading: CLHeading) {
        let rotationAngle = heading.magneticHeading - mapView.camera.heading
        
        userLocationHeadingSubviewRotate(to: rotationAngle)
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for headingView in views where headingView.annotation?.isKind(of: MKUserLocation.self) ?? false {
            userLocationHeadingSubview.removeFromSuperview()

            headingView.canShowCallout = false
            
            if let heading = locationManager.heading {
                userLocationHeadingSubviewRotate(to: heading)
            }
            
            headingView.addSubview(userLocationHeadingSubview)
            
            userLocationHeadingSubview.center = CGPoint(x: headingView.frame.size.width/2, y: headingView.frame.size.height/2)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? MKPointAnnotationIcon else {
            return
        }
        
        annotationForUpdating = annotation
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {

    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {

    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let heading = locationManager.heading {
            userLocationHeadingSubviewRotate(to: heading)
        }
        
        let scale = Int((mapView.mapWidthMeters * 125 / Double(mapView.frame.maxX)).rounded())

        scaleLabel.text = "\(scale) m"
    }

    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        switch mode {
        case .followWithHeading:
            mapMode = .followWithHeading
        case .follow:
            mapMode = .follow
        default:
            mapMode = .free
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {

    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKTileOverlay {
            let tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay as! MKTileOverlay)
            
            return tileRenderer
        }

        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)

            switch mapView.overlays.count {
            case 1:
                polylineRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.75)
            case 2:
                polylineRenderer.strokeColor = UIColor.green.withAlphaComponent(0.75)
            case 3:
                polylineRenderer.strokeColor = UIColor.red.withAlphaComponent(0.75)
            default:
                polylineRenderer.strokeColor = UIColor.gray.withAlphaComponent(0.75)
            }

            polylineRenderer.lineWidth = 4

            return polylineRenderer
        }

        return MKOverlayRenderer()
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        let alert = UIAlertController(title: "Can not load map. \(error.localizedDescription)", message: "Show cashed OSM maps?", preferredStyle: .actionSheet)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: { ( _: UIAlertAction) -> Void in
            self.mapLayer = .mapOSM
        })
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - MKPointAnnotationIconDelegate
    
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didChangeIconTo icon: UIImage, withCenterOffset centerOffset: CGPoint, withIconView iconView: UIImageView) {
        if let annotationView = mapView.view(for: annotation) {
            if annotation.isSaved {
                if annotation.isActive {
                    annotationView.image = icon
                    annotationView.centerOffset = centerOffset

                    annotationView.addSubview(iconView)

                    let iconSize = iconView.image!.size
                    let deltaBetweenIcons: CGFloat = 3

                    iconView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)

                    iconView.center.x = icon.size.width/2
                    // center is position of new anchor point, it will be 0
                    iconView.center.y = 0 - deltaBetweenIcons
                    iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

                    annotationView.calloutOffset = CGPoint(x: 0, y: -iconSize.height - deltaBetweenIcons)
                    
                    
                    UIView.animate(withDuration: 0.27, animations: {
                        iconView.transform = CGAffineTransform.identity
                    }, completion: { (_: Bool) in

                    })
                } else {
                    UIView.animate(withDuration: 0.27, animations: {
                        iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    }, completion: { (_: Bool) in
                        iconView.removeFromSuperview()
                        annotationView.calloutOffset = CGPoint(x: 0, y: 0)
                        annotationView.centerOffset = centerOffset
                        annotationView.image = icon
                    })
                }
            } else {
                annotationView.image = icon
                annotationView.centerOffset = centerOffset
            }
        }
    }
    
    func pointAnnotationIcon(_ annotation: MKPointAnnotationIcon, didSave isSaved: Bool) {
        if let annotationView = mapView.view(for: annotation) {
            annotationView.canShowCallout = isSaved

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(annotationTapped(_:)))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            annotationView.addGestureRecognizer(tapGesture)
        }
    }

    // MARK: - CLLocationManagerDelegate
    
    private func mapViewNavigateTo(location: CLLocation, animated: Bool = false, withDistance: CLLocationDistance? = nil) {
        if let distance = withDistance {
            let viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance)
            mapView.setRegion(viewRegion, animated: animated)
        } else {
            mapView.setCenter(location.coordinate, animated: animated)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer {
            currentLocation = locations.last
        }
        
        if currentLocation == nil {
            if let userLocation = locations.last {
                mapViewNavigateTo(location: userLocation, animated: false, withDistance: 2000)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userLocationHeadingSubviewRotate(to: newHeading)
    }
    
    // MARK: - Bottom Menu
    
    enum MenuState {
        enum ActivePointState {
            case forAdding
            case forUpdating
        }
        
        static let menuHeightExpanded = 199.0
        static let menuHeightCollapsed = 109.0
        
        static let deletePointButtonAnimator = PercentAnimator(alpha: 0.5, rotationAngle: PercentAnimator.radians(fromDegrees: -179.99999), transitionX: 0, transitionY: 133 - 16)

        static let toPointRouteButtonAnimator = PercentAnimator(alpha: 0.75, rotationAngle: PercentAnimator.radians(fromDegrees: -90), transitionX: 0, transitionY: 133 - 75)
        
        static let toPointLabelAnimator = PercentAnimator(alpha: 0, rotationAngle: 0, transitionX: 0, transitionY: 0)
        
        case withoutActivePoint(height: Double, dragged: Bool)
        case withActivePoint(height: Double, dragged: Bool, activePointState: ActivePointState)
        case initialize
        
        var percentAnimation: Double {
            switch self {
            case .withoutActivePoint, .initialize:
                return 1
            case .withActivePoint(let height, _, _):
                if height <= MenuState.menuHeightCollapsed {
                    return 0
                } else if height >= MenuState.menuHeightExpanded {
                    return 1
                } else {
                    return (height - MenuState.menuHeightCollapsed)/(MenuState.menuHeightExpanded - MenuState.menuHeightCollapsed)
                }
            }
        }
        
        var menuHeight: CGFloat {
            switch self {
            case let .withoutActivePoint(height, dragged):
                if dragged {
                    return CGFloat(height)
                } else {
                    return CGFloat(MenuState.menuHeightCollapsed)
                }
            case .initialize:
                return CGFloat(MenuState.menuHeightCollapsed)
            case .withActivePoint(let height, let dragged, _):
                if dragged {
                    return CGFloat(height)
                } else {
                    return CGFloat(MenuState.menuHeightExpanded)
                }
            }
        }
        
        private func transform(forAnimator animator: PercentAnimator) -> CGAffineTransform {
            switch self {
            case .withoutActivePoint, .initialize:
                return animator.startTransform
            case .withActivePoint:
                switch self.percentAnimation {
                case 0:
                    return animator.startTransform
                case 1:
                    return animator.endTransform
                default:
                    return animator.transform(forPercent: self.percentAnimation)
                }
            }
        }
        
        private func alpha(forAnimator animator: PercentAnimator) -> CGFloat {
            switch self {
            case .withoutActivePoint, .initialize:
                return animator.startAlpha
            case .withActivePoint:
                switch self.percentAnimation {
                case 0:
                    return animator.startAlpha
                case 1:
                    return animator.endAlpha
                default:
                    return animator.alpha(forPercent: self.percentAnimation)
                }
            }
        }
        
        var deletePointButtonTransform: CGAffineTransform {
            let animator = MenuState.deletePointButtonAnimator
            
            return transform(forAnimator: animator)
        }
        
        var deletePointButtonAlpha: CGFloat {
            let animator = MenuState.deletePointButtonAnimator

            return alpha(forAnimator: animator)
        }
        
        var toPointRouteButtonTransform: CGAffineTransform {
            let animator = MenuState.toPointRouteButtonAnimator
            
            return transform(forAnimator: animator)
        }
        
        var toPointRouteButtonAlpha: CGFloat {
            let animator = MenuState.toPointRouteButtonAnimator
            
            return alpha(forAnimator: animator)
        }
        
        var toPointLabelAlpha: CGFloat {
            let animator = MenuState.toPointLabelAnimator
            
            return alpha(forAnimator: animator)
        }
    }
    
    var menuState: MenuState = MenuState.initialize {
        didSet {
            switch menuState {
            case .initialize:
                addPointButton.isHidden = true
                removePointButton.isHidden = true
                toPointLabel.isHidden = true
                toPointRouteButton.isHidden = true
                closePointButton.isHidden = true

                bottomMenuHeight.constant = menuState.menuHeight
                closePointButton.transform = menuState.deletePointButtonTransform
                toPointRouteButton.transform = menuState.toPointRouteButtonTransform

                closePointButton.alpha = menuState.deletePointButtonAlpha
                toPointRouteButton.alpha = menuState.toPointRouteButtonAlpha
                
                toPointLabel.alpha = self.menuState.toPointLabelAlpha

                view.layoutIfNeeded()
            case .withoutActivePoint(_, let dragged):
                bottomMenuHeight.constant = menuState.menuHeight

                if dragged {
                    mapView.isUserInteractionEnabled = false
                    UIView.animate(withDuration: 0.1) {
                        self.view.layoutIfNeeded()
                    }
                } else {
                    mapView.isUserInteractionEnabled = false

                    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
                        self.closePointButton.transform = self.menuState.deletePointButtonTransform
                        self.toPointRouteButton.transform = self.menuState.toPointRouteButtonTransform
                        
                        self.closePointButton.alpha = self.menuState.deletePointButtonAlpha
                        self.toPointRouteButton.alpha = self.menuState.toPointRouteButtonAlpha
                        
                        self.toPointLabel.alpha = self.menuState.toPointLabelAlpha
                        
                        self.view.layoutIfNeeded()
                    }, completion: { (_: Bool) -> Void in
                        self.mapView.isUserInteractionEnabled = true
                        self.bottomMenu.isUserInteractionEnabled = true
                        self.addPointButton.isHidden = true
                        self.removePointButton.isHidden = true
                        self.toPointLabel.isHidden = true
                        self.toPointRouteButton.isHidden = true
                        self.closePointButton.isHidden = true
                    })
                }
            case .withActivePoint(_, let dragged, let activePointState):
                bottomMenuHeight.constant = menuState.menuHeight
                
                if dragged {
                    mapView.isUserInteractionEnabled = false
                    bottomMenu.isUserInteractionEnabled = false

                    closePointButton.transform = menuState.deletePointButtonTransform
                    toPointRouteButton.transform = menuState.toPointRouteButtonTransform
                    
                    UIView.animate(withDuration: 0.1) {
                        self.closePointButton.alpha = self.menuState.deletePointButtonAlpha
                        self.toPointRouteButton.alpha = self.menuState.toPointRouteButtonAlpha
                        
                        self.toPointLabel.alpha = self.menuState.toPointLabelAlpha

                        self.view.layoutIfNeeded()
                    }
                } else {
                    if activePointState == .forAdding {
                        addPointButton.isHidden = false
                        removePointButton.isHidden = true
                    } else {
                        addPointButton.isHidden = true
                        removePointButton.isHidden = false
                    }

                    toPointLabel.isHidden = false
                    toPointRouteButton.isHidden = false
                    closePointButton.isHidden = false

                    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
                        self.closePointButton.transform = self.menuState.deletePointButtonTransform
                        self.toPointRouteButton.transform = self.menuState.toPointRouteButtonTransform
                        
                        self.closePointButton.alpha = self.menuState.deletePointButtonAlpha
                        self.toPointRouteButton.alpha = self.menuState.toPointRouteButtonAlpha
                        
                        self.toPointLabel.alpha = self.menuState.toPointLabelAlpha
                        
                        self.view.layoutIfNeeded()
                    }, completion: { (_: Bool) -> Void in
                        self.mapView.isUserInteractionEnabled = true
                        self.bottomMenu.isUserInteractionEnabled = true
                    })
                }
            }
        }
    }

    @IBAction func bottomMenuPanned(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            break
        case .changed:
            var menuHeight: Double

            switch menuState {
            case .initialize, .withoutActivePoint:
                menuHeight = MenuState.menuHeightCollapsed - Double(sender.translation(in: sender.view).y)
            case .withActivePoint:
                menuHeight = MenuState.menuHeightExpanded - Double(sender.translation(in: sender.view).y)
            }
            
            menuHeight = max(menuHeight, MenuState.menuHeightCollapsed)

            switch menuState {
            case .initialize, .withoutActivePoint:
                menuState = MenuState.withoutActivePoint(height: menuHeight, dragged: true)
            case .withActivePoint(_, _, let activePointState):
                menuState = MenuState.withActivePoint(height: menuHeight, dragged: true, activePointState: activePointState)
            }
        case .ended, .failed, .cancelled:
            switch menuState {
            case .withActivePoint(_, _, let activePointState):
                if menuState.percentAnimation == 0 {
                    closePointButtonTouchUpInside(closePointButton)
                } else {
                    menuState = .withActivePoint(height: MenuState.menuHeightExpanded, dragged: false, activePointState: activePointState)
                }
            default:
                menuState = .withoutActivePoint(height: MenuState.menuHeightCollapsed, dragged: false)
            }
        default:
            switch menuState {
            case .initialize, .withoutActivePoint:
                menuState = .withoutActivePoint(height: MenuState.menuHeightCollapsed, dragged: false)
            case .withActivePoint(_, _, let activePointState):
                menuState = .withActivePoint(height: MenuState.menuHeightExpanded, dragged: false, activePointState: activePointState)
            }
        }
    }
}

