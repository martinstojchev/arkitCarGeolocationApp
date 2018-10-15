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
    
    class func textNode(text: String) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
        if let material = geometry.firstMaterial {
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = true
        }
        let textNode = SCNNode(geometry: geometry)
        
        geometry.font = UIFont.systemFont(ofSize: 1)
        textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)
        
        // Translate so that the text node can be seen
        let (min, max) = geometry.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, min.y - 0.5, 0)
        
        // Always look at the camera
        let node = SCNNode()
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        node.constraints = [billboardConstraint]
        
        node.addChildNode(textNode)
        
        return node
    }
    
    
}

fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
    return input.rawValue
}
