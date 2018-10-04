//
//  Annotations.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/4/18.
//  Copyright © 2018 Martin. All rights reserved.
//


import MapKit
import Contacts

class MyAnnotations: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        
        self.title = title
        self.discipline = discipline
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String?{
        
        return locationName
    }
    
    func mapItem() -> MKMapItem {
        
        let addressDict = [CNPostalAddressStateKey: subtitle!]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        
        return mapItem
        
    }
    
}

