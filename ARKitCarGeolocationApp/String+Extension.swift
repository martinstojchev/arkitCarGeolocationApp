//
//  String+Extension.swift
//  ARKitCarGeolocationApp
//
//  Created by Martin on 10/2/18.
//  Copyright © 2018 Martin. All rights reserved.
//

import UIKit

extension String {
    
    func image() -> UIImage? {
        
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 90)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    
}
