//
//  SCNNode Extension.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/15/18.
//  Copyright © 2018 Martin. All rights reserved.
//

import UIKit
import ARKit

extension SCNNode {
    
    
    class func lineNode(length: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNCapsule(capRadius: 0.6, height: length)
        geometry.materials.first?.diffuse.contents = color
        let line = SCNNode(geometry: geometry)
        
        let node = SCNNode()
        node.eulerAngles = SCNVector3Make(Float.pi/2, 0, 0)
        node.addChildNode(line)
        
        return node
    }
    
    
}
