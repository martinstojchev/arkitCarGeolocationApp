//
//  ViewController.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/2/18.
//  Copyright © 2018 Martin. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import CoreLocation
import PusherSwift
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var showInARButton: UIButton!
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var myPositionButton: UIButton!
    @IBOutlet weak var showMapButton: UIButton!
    
    var resultSearchController: UISearchController? = nil
    var selectedPin: MKPlacemark? = nil
    
    var metricsForDistance: String = "m"
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var modelNode: SCNNode!
    let rootNodeName = "Car"
    var originalTransform: SCNMatrix4!
    var heading: Double! = 0.0
    
    var pointPositions: [SCNVector3] = []
    var locationPoints: [Location] = []
    var customLocations: [Location] = []
    var distances: [CLLocationDistance] = []
     // using for calculating distances between points
    var currentLocationForDistance: CLLocation!
    var startingLocationPin: MyAnnotations!
    var modelScene: SCNScene!
    var nodePoints: [SCNNode] = []
    var isCustomNode: Bool = false
    let impact = UIImpactFeedbackGenerator()
    
    
    
    var distance: Float! = 0.0 {
      
        didSet {
        setStatusText()
        }
    }
    
    var status: String! {
        
        didSet {
            setStatusText()
        }
    }
    
    //Location stuff
    
    var requestedRoutePoints: [CLLocationCoordinate2D] = []
    var startPointCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var endPointCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var routeSteps: [MKRoute.Step] = []
    var pinPointsCoordinate: [CLLocationCoordinate2D] = []
    var usersCurrenLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestedRouteForTap: Bool = false
    var directionsForRoute:[MKDirections] = []
    var annotationsOnMap: [MyAnnotations] = []
    
    // Drawing path
     private var drawingNodes = [DynamicGeometryNode]()
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
         myPositionButton.isHidden = false
        
        //Location stuff
        checkLocationServices()
        
        self.mapView.delegate = self
        self.setupGesture()
        
        //searchController
        let locationSearchTable = storyboard?.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = resultSearchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.handleMapSearchDelegate = self
        
        
        locationSearchTable.mapView = mapView
        
        //Set the view's delegate
        sceneView.delegate = self
        
        //Create a new scene
        let scene = SCNScene()
        
        //Set the scene to the view
        sceneView.scene = scene
        
        //Start location services
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        //Set the initial status
        status = "Getting user location..."
        
        //Set a padding in the text view
        statusTextView.textContainerInset = UIEdgeInsets.init(top: 20.0, left: 10.0, bottom: 10.0, right: 0.0)
        
        
        
    }
    
    func setStatusText(){
        
        var text = "Status: \(status!)\n"
        text += "Distance: \(String(format: "%.2f \(metricsForDistance)", distance))"
        statusTextView.text = text
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear called")
        

        //Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        //The option gravityAndHeading will set the y-axis to the direction of gravity as detected by the device, and the x and z-axes to the longitude and latitude
        //directions as measured by Location Services.
        configuration.worldAlignment = .gravityAndHeading

        //Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear called")
        //Pause the view's session
        sceneView.session.pause()
        
       
    }
    
    //Mark: - CLLocationManager
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         //Implementing this method is required
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
           locationManager.requestLocation()
        }
    }

    //Once the user's location is received, take the last element of the array, update the status, and connect to Pusher
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {
            userLocation = location
            status = "User location founded"
            
            
            //self.getLocationsForAR()



        }
    }
    
    //Mark: - Utility methods
    
    func getLocationsForAR(){
        
        
        annotationsOnMap.removeFirst()
        
        for annotation in annotationsOnMap {
            let location = Location(latitude: annotation.coordinate.latitude,
                                    longitude: annotation.coordinate.longitude,
                                    heading: 0,
                                    instructions: annotation.locationName)
            
            locationPoints.append(location)
        }
        
        
        for location in locationPoints {
            
            self.heading = location.getHeading()
            
            let latitude = location.getLatitude()
            let longitude = location.getLongitude()
            let instructions = location.getInstructions()
            
            self.updateLocation(latitude, longitude, instructions)
            
            
        }
        
        //custom location pin
        let soborenHram = Location(latitude: 41.9963565, longitude: 21.4272423, heading: 0, instructions: "Soboren hram")
        self.updateLocation(soborenHram.latitude, soborenHram.longitude, soborenHram.instructions)
        //print("soboren hram updateLocation called")
        customLocations.append(soborenHram)
        let finki = Location(latitude: 42.004104256225155, longitude: 21.40970349311829, heading: 0, instructions: "FINKI")
        self.updateLocation(finki.latitude, finki.longitude, finki.instructions)
        customLocations.append(finki)
        
        self.status = "All location pinned on the map"
        
        sceneView.isHidden = false
        statusTextView.isHidden = false
        showMapButton.isHidden = false
    }
    
    func calculateDistanceFromMyLocation(toLocation location: CLLocation) -> Float {
        
        
        let userLocation = CLLocation(latitude: usersCurrenLocation.latitude, longitude: usersCurrenLocation.longitude)
        let endLocation  = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        
         let distanceFromUser = Float(endLocation.distance(from: userLocation))
        
        return distanceFromUser
        
    }
    
    func calculateDistanceBetweenPoints(locations: [Location]){
        
        if (locations.isEmpty){
            print("locations is empty array")
        }
        else {
            
            currentLocationForDistance = CLLocation(latitude: locations[0].latitude, longitude: locations[0].longitude)
            
            //var i = 1
            print("locations count: \(locations.count)")
            for i in 1..<locations.count {
                
                print("i: \(locations[locations.count-1])")
                var secondLocation = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
                
                print("current location: \(currentLocationForDistance)")
                print("second location: \(secondLocation)")
                let distance = currentLocationForDistance.distance(from: secondLocation)
            
                if i == locations.count-1 {
                distances.append(distance)
                    
                }
                else {
                distances.append(distance)
                
                currentLocationForDistance = secondLocation
                
                }
                
            }
            
//            for distance in distances {
//
//                print(distance)
//            }
            
            
        }
        
    }
    
    func updateLocation(_ latitude: Double, _ longitude: Double, _ instructions: String){
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        // call this method only once
        if distances.isEmpty{
          calculateDistanceBetweenPoints(locations: locationPoints)
        }
        
        print("updateLocation(),sceneView.rootNode: \(sceneView.scene.rootNode)")
        
        print("update location called")
        
        //if self.modelNode == nil {
             //let modelScene = SCNScene(named: "art.scnassets/Car.dae")!
             //self.modelNode = modelScene.rootNode.childNode(withName: rootNodeName, recursively: true)!
            // Replace the car 3D model with point
            modelScene = SCNScene(named: "art.scnassets/pointScene.scn")
            var ballShape = SCNSphere(radius: 0.40)
            //ballShape.firstMaterial = SCNMaterial()
            let ballMaterial = SCNMaterial()
            ballMaterial.diffuse.contents = UIColor.red
            ballShape.materials = [ballMaterial]
        
            var ballNode = SCNNode(geometry: ballShape)
            ballNode.name = "ball"
            modelScene?.rootNode.addChildNode(ballNode)
            self.modelNode = modelScene?.rootNode.childNode(withName: "ball", recursively: true)
            
            
            
        //You need to move the pivot of the model to its center in the y-axis, so it can be rotated without changing its position
        
            let (minBox, maxBox) = self.modelNode.boundingBox
            self.modelNode.pivot = SCNMatrix4MakeTranslation(0, (maxBox.y - minBox.y)/2, 0)
            
        // Save original transform to calculate future rotations
            self.originalTransform = self.modelNode.transform
           
            // Begin animation
            //SCNTransaction.begin()
            //SCNTransaction.animationDuration = 1.0
            
        // Position the model in the correct place
            positionModel(location)
            
        // Add the model to the scene
            sceneView.scene.rootNode.addChildNode(self.modelNode)
        
        
        
        let arrow: SCNNode!
        
        if (instructions.contains("left")){
            arrow = makeBillboardNode("⬅️".image()!)
        }
        else if (instructions.contains("right")){
            arrow = makeBillboardNode("➡️".image()!)
        }
        else if (instructions.contains("End point")){
            arrow = makeBillboardNode("🚩".image()!)
            // Add text on top of the node
            
            let geometry = SCNText(string: "End", extrusionDepth: 0.01)
            //geometry.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
            if let material = geometry.firstMaterial {
                material.diffuse.contents = UIColor.white
                material.isDoubleSided = true
            }
            let textNode = SCNNode(geometry: geometry)
            
            geometry.font = UIFont.systemFont(ofSize: 10)
            textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)
            textNode.position = SCNVector3Make(-8, 4, 0)
            textNode.constraints = [SCNBillboardConstraint()]
            
            arrow.addChildNode(textNode)
        }
        else if (instructions != ""){
            //custom text node
            var distanceFromMe = calculateDistanceFromMyLocation(toLocation: location)
            var metricsForCustomDistance = "m"
            
            if(distanceFromMe > 1000){
                distanceFromMe = distanceFromMe / 1000
                metricsForCustomDistance = "km"
            }
            else{
                metricsForCustomDistance = "m"
            }
            let distanceString = String(format: "%.2f", distanceFromMe)
            let showingDistanceString = "\(distanceString)\(metricsForCustomDistance)"
            
            
            print("custom text node")
            arrow = makeBillboardNode("🏠".image()!)
            
            isCustomNode = true
            
            let text = "\(instructions) \(showingDistanceString)"
            
            let geometry = SCNText(string: text, extrusionDepth: 0.01)
            //geometry.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
            if let material = geometry.firstMaterial {
                material.diffuse.contents = UIColor.white
                material.isDoubleSided = true
            }
            let textNode = SCNNode(geometry: geometry)
            
            geometry.font = UIFont.systemFont(ofSize: 10)
            textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)
            textNode.position = SCNVector3Make(-8, 4, 0)
            textNode.constraints = [SCNBillboardConstraint()]
            
            arrow.addChildNode(textNode)
            
        }
        else {
            arrow = SCNNode()
        }
       
        if(!isCustomNode){
            
            // Add model node in the array for drawing line between them
            nodePoints.append(self.modelNode)
        }
        
        // Postion it on top of the node
            arrow.position = SCNVector3Make(0, 4, 0)
        // Add it as a child of the car model
            self.modelNode.addChildNode(arrow)
        
        isCustomNode = false
        
        
        // Draw the line between the last two points from pointPositions array
        
        if (nodePoints.count == 2){
            
 
            let startNode = nodePoints[0]
            let endNode   = nodePoints[1]
            
            let distance = (endNode.position - startNode.position).length()
            let drawLineNode = drawLine(from: startNode, to: endNode, length: distance)
            
            let textNode = addTextNode(onNode: startNode, text: "Start")
            
            sceneView.scene.rootNode.addChildNode(textNode)

            nodePoints.remove(at: 0)
            print("deletef the first element from nodePoints array, count after removing is: \(nodePoints.count)")
                
        }
        else {
            print("pointPositions count < 2 : \(pointPositions.count) ")
        }
            
            // End animation
           // SCNTransaction.commit()
            
            print("updating location.....")
            
        print("nodePoints count: \(nodePoints.count)")
    }
    
    private func drawLine(from: SCNNode, to: SCNNode, length: Float) -> SCNNode {
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: UIColor.red)
        from.addChildNode(lineNode)
        lineNode.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to.position)
        return lineNode
    }
    
    private func addTextNode(onNode node: SCNNode, text: String) -> SCNNode {
        
        let textNode = SCNNode.textNode(text: text)
        node.addChildNode(textNode)
        
        return node
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        
        
    }
    
    func positionModel(_ location: CLLocation) {
        
        // Rotate node
        self.modelNode.transform = rotateNode(Float(-1 * (self.heading - 180).toRadians()), self.originalTransform)
        
        // Translate node
        self.modelNode.position = translateNode(location)
        
        // Add the point position to pointPosition array to use it later for drawing 3d line between them
        pointPositions.append(self.modelNode.position)
        print("added to pointPositions: \(self.modelNode.position)")
        
        //Scale node
        self.modelNode.scale = scaleNode(location)
        
        print("postioning the model")
    }
    
    // In ARKit, rotation in the y-axis is counterclockwise (and handled in radians), so we need to substract 180 degrees and make the angle negative.
    // This is the definition od the method rotateNode:
    
    func rotateNode(_ angleInRadians: Float, _ transform: SCNMatrix4) -> SCNMatrix4 {
        
        let rotation = SCNMatrix4MakeRotation(angleInRadians, 0, 1, 0)
        return SCNMatrix4Mult(transform, rotation)
    }
    
    // Scale the node in proportion to the distance. They are inversely proportional - the greater the distance, the less the scale.
    // In my case, i just divide 1000 by the distance and don't allow the value to be less than 1.5 or great than 3:
    
    func scaleNode(_ location: CLLocation) -> SCNVector3 {
        
        //let scale = min( max(Float(1000 / distance), 1.5), 3)
        return SCNVector3(x: 3, y: 3, z: 3)
    }
    
    // To translate the node, you have to calculate the transformation matrix and get the position values that matrix (from its fourth column, referenced by a zero-based index):
    
    func translateNode(_ location: CLLocation) -> SCNVector3 {
        
        let locationTransform = transformMatrix(matrix_identity_float4x4, userLocation, location)
        return positionFromTransform(locationTransform)
    }
    
    func positionFromTransform(_ transform: simd_float4x4) -> SCNVector3{
        
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func transformMatrix(_ matrix: simd_float4x4, _ originLocation: CLLocation, _ driverLocation: CLLocation) -> simd_float4x4 {
        
        let bearing = bearingBetweenLocations(userLocation, driverLocation)
        let rotationMatrix = rotateAroundY(matrix_identity_float4x4, Float(bearing))
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        
        let translationMatrix = getTranslationMatrix(matrix_identity_float4x4, position)
        
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        
        return simd_mul(matrix, transformMatrix)
        
    }
    
    func getTranslationMatrix(_ matrix: simd_float4x4, _ translation: vector_float4) -> simd_float4x4 {
        
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    func rotateAroundY(_ matrix: simd_float4x4, _ degrees: Float) -> simd_float4x4 {
        
        var matrix = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        
        return matrix.inverse
        
    }
    
    
    func bearingBetweenLocations(_ originLocation: CLLocation, _ driverLocation: CLLocation) -> Double {
        
        let lat1 = originLocation.coordinate.latitude.toRadians()
        let lon1 = originLocation.coordinate.longitude.toRadians()
        
        let lat2 = driverLocation.coordinate.latitude.toRadians()
        let lon2 = driverLocation.coordinate.longitude.toRadians()
        
        let longitudeDiff = lon2 - lon1
        
        let y = sin(longitudeDiff) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDiff)
        
        return atan2(y, x)
    }
    
    func makeBillboardNode(_ image: UIImage) -> SCNNode {
        
        let plane = SCNPlane(width: 10, height: 10)
        plane.firstMaterial?.diffuse.contents = image
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("didFailWithError method called")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by representing an overlay
        print("sessionWasInterrupted method called")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("sessionInterruptionEnded method called")
    }
    
    
    
    
    //Show the map from the SceneView
    @IBAction func showMap(_ sender: Any) {
        
        sceneView.isHidden = true
        mapView.isHidden = false
        showMapButton.isHidden = true
        statusTextView.isHidden = true
        cancelButton.isHidden = false
        showInARButton.isHidden = false
        myPositionButton.isHidden = false
        
         self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
        
    }
    
    
    
    // Dealing with location stuff
    
    func setupGesture() {
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPress(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        longPressGesture.delegate = self
        self.mapView.addGestureRecognizer(longPressGesture)
        
    }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer){
        
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {
            
            if requestedRouteForTap == false {
                requestedRouteForTap = true
                
                let touchLocation = gestureRecognizer.location(in: mapView)
                let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
                print("Tapped location: \(locationCoordinate.latitude),\(locationCoordinate.longitude)")
                impact.impactOccurred()
                requestRoute(endLocation: locationCoordinate)
                cancelButton.isHidden = false
                showInARButton.isHidden = false
                return
                
            }
        }
        
        if gestureRecognizer.state != UIGestureRecognizer.State.began {
            return
        }
        
    }
    
     func requestRoute(endLocation: CLLocationCoordinate2D){
        
        startPointCoordinates = usersCurrenLocation
        endPointCoordinates   = endLocation
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: usersCurrenLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation, addressDictionary:nil))
        request.requestsAlternateRoutes = true
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directionsForRoute.append(directions)
        
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            var allRoutes = unwrappedResponse.routes
            let bestRoute = allRoutes.sorted(by: {$0.expectedTravelTime <
                $1.expectedTravelTime})[0]
            
            
            //for route in unwrappedResponse.routes {
            
            self.mapView.addOverlay(bestRoute.polyline)
            self.mapView.setVisibleMapRect(bestRoute.polyline.boundingMapRect, animated: true)
            self.routeSteps = bestRoute.steps
            self.printRouteSteps(steps: self.routeSteps)
            self.addPinPointsToMap(pinPointsCoordinate: self.pinPointsCoordinate, rootSteps: self.routeSteps)
            
            print("best route showed")
            //}
        }
        
        
    }
    
    func printRouteSteps(steps: [MKRoute.Step]) {
        
        for routeStep in steps {
            print("routeStep: \(routeStep.instructions, routeStep.polyline.coordinate)")
        }
    }
    
    func addPinPointsToMap(pinPointsCoordinate: [CLLocationCoordinate2D], rootSteps: [MKRoute.Step]) {
        
         startingLocationPin = MyAnnotations(title: "Start",
                                                locationName: "Start point",
                                                discipline: "",
                                                coordinate: startPointCoordinates
                                            )
        
        //pin the starting point
        annotationsOnMap.append(startingLocationPin)
        mapView.addAnnotation(startingLocationPin)
        
        for pinPoint in pinPointsCoordinate {
            
            let pinLatitude  = pinPoint.latitude
            let pinLongitude = pinPoint.longitude
            var stepDirection = ""
            
            for step in rootSteps {
                
                let stepLatitude  = step.polyline.coordinate.latitude
                let stepLongitude = step.polyline.coordinate.longitude
                
                if (stepLatitude == pinLatitude && stepLongitude == pinLongitude){
                    
                    
                    stepDirection = step.instructions
                }
                
            }
            
            let pinAnnotation = MyAnnotations(title: "",
                                              locationName: stepDirection,
                                              discipline: "",
                                              coordinate: pinPoint)
            
            annotationsOnMap.append(pinAnnotation)
            mapView.addAnnotation(pinAnnotation)
            print("annotationsOnMap count: \(annotationsOnMap.count)")
            
            
        }
        
        //pin the ending point
        
        let endingLocationPin    = MyAnnotations(title: "End",
                                                 locationName: "End point",
                                                 discipline: "",
                                                 coordinate: endPointCoordinates
        )
        
        
        annotationsOnMap.append(endingLocationPin)
        mapView.addAnnotation(endingLocationPin)
        print("endPointCoordinate: lat: \(endingLocationPin.coordinate.latitude), lon: \(endingLocationPin.coordinate.longitude)")
        
        
        
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        
        //renderer.alpha = 0.1
        
        print("overlays count: \(mapView.overlays.count)")
        //coloring the routes
        if(overlay is MKPolyline){
            
            print("overlay is MKPolyline")
            if mapView.overlays.count == 1 {
                renderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            }
            else if (mapView.overlays.count == 2) {
                renderer.strokeColor = UIColor.green.withAlphaComponent(0.5)
            }
            else if (mapView.overlays.count == 3) {
                renderer.strokeColor = UIColor.red.withAlphaComponent(0.5)
            }
        }
        
        
        
        let polyline = overlay as! MKPolyline
        var polyLinePoints = polyline.points()
        

        
        var i = 0
        while i < polyline.pointCount {
            
            requestedRoutePoints.append(polyLinePoints.pointee.coordinate)
            print("polyline pointee coordinate: \(polyLinePoints.pointee.coordinate)")
            print("polyline pointee coordinate: \(polyLinePoints.pointee.coordinate)")
            
            
            //            let pinPoint = MyAnnotations(title: "pin",
            //                                  locationName: "\(polyLinePoints.pointee.coordinate.latitude), \(polyLinePoints.pointee.coordinate.longitude)",
            //                                  discipline: ".",
            //                                  coordinate:polyLinePoints.pointee.coordinate )
            //            mapView.addAnnotation(pinPoint)
            pinPointsCoordinate.append(polyLinePoints.pointee.coordinate)
            
            
            polyLinePoints = polyLinePoints.successor()
            i = i + 1
        }
        
        for ppCoordinate in pinPointsCoordinate {
            
            
            print("pinPointsCoordinate: lat:\(ppCoordinate.latitude), lon:\(ppCoordinate.longitude)")
            
        }
        
        print("pinPointsCoordinate count: \(pinPointsCoordinate.count)")
        print("Finished iterating the points.....")
        
        
        
        
        
        
        
        print("requestedRoutePoints array number of elements \(requestedRoutePoints.count)")
        
        return renderer
    }
    
    
    func setupLocationManager() {
        
        // locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
    }
    
    func checkLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
            //setup our location manager
            setupLocationManager()
            checkLocationAuthorization()
            
            
            
        }
        else {
            // Show alert letting the user know they have to turn this on.
        }
        
        
    }
    
    func checkLocationAuthorization(){
        
        switch CLLocationManager.authorizationStatus(){
            
        case .authorizedWhenInUse:
            
            mapView.showsUserLocation = true
            //centerViewOnUserLocation()
            print("authorization when in use")
            locationManager.startUpdatingLocation()
            //print("userLocation in setupLocation manager: \(userLocation)")
            
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
            
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        //print("Updating user's location: \(userLocation.coordinate)")
        
        // Calculate and display the distance between user's location and end point location
        let currentLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let endPoint = CLLocation(latitude: endPointCoordinates.latitude, longitude: endPointCoordinates.longitude)
        
        var distanceForDisplay: Float = 0.0
        distanceForDisplay = Float(endPoint.distance(from: currentLocation))
        if(distanceForDisplay > 1000.0){
            distanceForDisplay = distanceForDisplay / 1000
            metricsForDistance = "km"
        }
        else {
            metricsForDistance = "m"
        }
        
        self.distance = distanceForDisplay
        
        if (usersCurrenLocation.latitude == 0 && usersCurrenLocation.longitude == 0) {
            usersCurrenLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            print("User's current location: \(usersCurrenLocation)")
            
            let viewRegion = MKCoordinateRegion(center: usersCurrenLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: true)
            
        }
    }



    @IBAction func cancelRoute(_ sender: Any) {
    
        
        
        
        //mapView.removeAnnotations(annotationsOnMap)
        mapView.removeAnnotations(mapView.annotations)
        pinPointsCoordinate = []
        annotationsOnMap    = []
        requestedRoutePoints = []
        locationPoints       = []
        distances           = []
        print("requestedRoutePoints reseted")
        
        print("mapView annotations: \(mapView.annotations)")
        //print("mapView annotations: \(mapView.annotations[1])")
        
        // Remove the starting point annotation when backing from ar map to mapview
        if (mapView.annotations.count > 1){
            mapView.removeAnnotation(startingLocationPin)
        }
        
        print("annotationsOnMap reseted: \(annotationsOnMap.count)")
        
        //print("Annotations removed from map")
        
        if mapView.overlays.count > 0 {
            
            mapView.removeOverlays(mapView.overlays)
            
            
        }
        requestedRouteForTap = false
        cancelButton.isHidden = true
        showInARButton.isHidden = true
        
        resultSearchController?.searchBar.text = ""
        //reset the ar world route
        
        

        
        let rootNode = sceneView.scene.rootNode
        print("rootNode: \(rootNode)")

        rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()

        }

        print("rootNode after removing: \(rootNode)")
        print("sceneView.rootNode: \(sceneView.scene.rootNode)")

        //sceneView.scene = SCNScene()
        
    }
    
    @IBAction func showAR(_ sender: Any) {
        
        
        print("showAR root node: \(sceneView.scene.rootNode)")
        //print("showAR method:  annotationsOnMap count: \(annotationsOnMap.count)")
//        for annotation in annotationsOnMap {
//            print("annotation step: \(annotation.locationName), annotationCoordinates: \(annotation.coordinate) ")
//        }
        //show the ARCamera
        mapView.isHidden = true
        cancelButton.isHidden = true
        showInARButton.isHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        myPositionButton.isHidden = true
        
        
        self.getLocationsForAR()
        
        

        
    }
    
    
    @IBAction func showMyLocation(_ sender: Any) {
        
        print("usersCurrenLocation: \(usersCurrenLocation)")
        print("userLocation: \(userLocation)")
        
            
            let viewRegion = MKCoordinateRegion(center:usersCurrenLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            // return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "walk"), for: .normal)
        button.addTarget(self, action: #selector(handleMapView), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        
        return pinView
        
    }
    
    
    
    @objc func handleMapView(){
        // get the coordinates from the selectedPin and request the direction
        
        let selectedPinCoordinate = selectedPin?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        requestRoute(endLocation: selectedPinCoordinate)
        
        print("requested route for searched pin")
        
        cancelButton.isHidden = false
        showInARButton.isHidden = false
        
    }
    
    
    


}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        print("SCNGeometry source: \(source)")
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        //element.minimumPointScreenSpaceRadius = 20
        //let element2 = SCNGeometryElement(indices: indices, primitiveType: .polygon)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension ViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        
        //cache the pin
        selectedPin = placemark
        //clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality{
             annotation.subtitle = "\(city)"
        }
        
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion.init(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        
    }
    
}

