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

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var modelNode: SCNNode!
    let rootNodeName = "Car"
    var originalTransform: SCNMatrix4!
    var heading: Double! = 0.0
    
    var pointPositions: [SCNVector3] = []
    var locationPoints: [Location] = []
    
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
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        text += "Distance: \(String(format: "%.2f m", distance))"
        statusTextView.text = text
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            
            self.getLocationsForAR()
            
            
            
        }
    }
    
    //Mark: - Utility methods
    
    func getLocationsForAR(){
        
        var location1 = Location(latitude: 41.99956834316254, longitude: 21.42547597676179, heading: 0, instructions: "")
        locationPoints.append(location1)
        var location2 = Location(latitude: 41.99934488162398, longitude: 21.425885516550835, heading: 0, instructions: "")
        locationPoints.append(location2)
        var location3 = Location(latitude: 41.999316550791264, longitude: 21.4259374843505, heading: 0, instructions: "Turn right onto Bulevar Sveti Kliment Ohridski")
        locationPoints.append(location3)
        var location4 = Location(latitude: 41.9989355932921, longitude: 21.42563942387369, heading: 0, instructions: "")
        locationPoints.append(location4)
        var location5 = Location(latitude: 41.99872705154121, longitude: 21.42551067784092, heading: 0, instructions: "")
        locationPoints.append(location5)
        var location6 = Location(latitude: 41.99857332743704, longitude:21.425441610958757, heading: 0, instructions: "")
        locationPoints.append(location6)
        var location7 = Location(latitude: 41.99827375821768, longitude: 21.42535971976477, heading: 0, instructions: "")
        locationPoints.append(location7)
        var location8 = Location(latitude: 41.998232183977954, longitude: 21.42534840419549, heading: 0, instructions: "Turn left onto Bulevar Partizanski Odredi")
        locationPoints.append(location8)
        var location9 = Location(latitude: 41.998167894780636, longitude:21.425554934289664 , heading: 0, instructions: "Turn left onto Bulevar Sveti Kliment Ohridski")
        locationPoints.append(location9)
        var location10 = Location(latitude:41.99847433716057 , longitude: 21.42565115853813, heading: 0, instructions: "")
        locationPoints.append(location10)
        var location11 = Location(latitude: 41.99856905266642, longitude: 21.42568099811342, heading: 0, instructions: "")
        locationPoints.append(location11)
        var location12 = Location(latitude: 41.99875018559395, longitude: 21.425779904570874, heading: 0, instructions: "")
        locationPoints.append(location12)
        var location13 = Location(latitude: 41.99909862130879, longitude: 21.426021471020306, heading: 0, instructions: "")
        locationPoints.append(location13)
        var location14 = Location(latitude: 41.99913642369211, longitude: 21.426046784367884, heading: 0, instructions: "Turn right onto Ulica Orce Nikolov")
        locationPoints.append(location14)
        var location15 = Location(latitude: 41.999042294919484, longitude: 21.426239232864788, heading: 0, instructions: "The destination is on your left")
        locationPoints.append(location15)
        
        for location in locationPoints {
            
            self.heading = location.getHeading()
            
            let latitude = location.getLatitude()
            let longitude = location.getLongitude()
            let instructions = location.getInstructions()
            
            self.updateLocation(latitude, longitude, instructions)
            
            
        }
        
        self.status = "All location pinned on the map"
        
        
        
        
        
    }
    
    func updateLocation(_ latitude: Double, _ longitude: Double, _ instructions: String){
        
        print("update location called")
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.distance = Float(location.distance(from: userLocation))
        
        //if self.modelNode == nil {
             //let modelScene = SCNScene(named: "art.scnassets/Car.dae")!
             //self.modelNode = modelScene.rootNode.childNode(withName: rootNodeName, recursively: true)!
            // Replace the car 3D model with point
            let modelScene = SCNScene(named: "art.scnassets/pointScene.scn")
            var ballShape = SCNSphere(radius: 0.40)
            ballShape.firstMaterial = SCNMaterial()
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
        else {
            arrow = SCNNode()
        }
        // Create arrow from the emoji
        
        // Postion it on top of the car
            arrow.position = SCNVector3Make(0, 4, 0)
        // Add it as a child of the car model
            self.modelNode.addChildNode(arrow)
        
        // Draw the line between the last two points from pointPositions array
        
        if (pointPositions.count == 2){
            
             let startPointPosition = pointPositions[0]
             let endPointPosition   = pointPositions[1]
            
            print("startPointPosition: \(startPointPosition)")
            print("endPointPosition: \(endPointPosition)")
            
            let line = SCNGeometry.line(from: startPointPosition, to: endPointPosition)
            line.firstMaterial = SCNMaterial()
            line.firstMaterial?.fillMode = .fill
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3Make(0, -2, 0)
            
            sceneView.scene.rootNode.addChildNode(lineNode)
            
            pointPositions.remove(at: 0)
            print("deleted the first element from the poinPoints array, count after removing is: \(pointPositions.count) ")
                
        }
        else {
            print("pointPositions count < 2 : \(pointPositions.count) ")
        }
            
            // End animation
           // SCNTransaction.commit()
            
            print("updating location.....")
            
       // }
     //   else {
            
            
            // Position the model in the correct place
            //positionModel(location)
            
            
       // }
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
    


}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        element.pointSize = 15
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

