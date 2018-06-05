//
//  AnnotationPin.swift
//  smallsteps
//
//  Created by Cheryl Chen on 2018/6/5.
//  Copyright © 2018 group29. All rights reserved.
//

import MapKit
class AnnotationPin: NSObject, MKAnnotation{
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title:String, subtitle:String, coordinate: CLLocationCoordinate2D){
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
