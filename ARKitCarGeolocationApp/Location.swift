//
//  Location.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/4/18.
//  Copyright © 2018 Martin. All rights reserved.
//

import Foundation

class Location {
    
    var latitude:  Double = 0.0
    var longitude: Double = 0.0
    var heading:   Double = 0.0
    var instructions: String = ""
    
    
    init(latitude: Double, longitude: Double, heading: Double, instructions: String) {
        
        self.latitude     = latitude
        self.longitude    = longitude
        self.heading      = heading
        self.instructions = instructions
        
    }
    
    func getLatitude() -> Double{
        return latitude
    }
    
    func getLongitude() -> Double{
        return longitude
    }
    
    func getHeading() -> Double{
        return heading
    }
    
    func getInstructions() -> String{
        return instructions
    }
    
    
}
