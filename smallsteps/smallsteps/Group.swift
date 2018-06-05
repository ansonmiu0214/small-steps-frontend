//
//  Group.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation
import CoreLocation

class Group {
    var groupName: String
    var date: String
    var time: String
    var repeats: String
    var duration: String
    var location: CLLocation
    var adminID: String
    
    init(groupName: String, date:String, time:String, repeats:String, duration:String, location:CLLocation, adminID: String) {
        self.groupName = groupName
        self.date = date
        self.time = time
        self.repeats = repeats
        self.duration = duration
        self.location = location
        self.adminID = adminID
    }
}
