//
//  FloationPoint+Extension.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/2/18.
//  Copyright © 2018 Martin. All rights reserved.
//

import Foundation

extension FloatingPoint {
    
    func toRadians() -> Self{
        
         return self * .pi / 180
    }
    
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
}
