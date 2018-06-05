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
    var date: Int
    var time: Int
    var repeats: String
    var duration: String
    var location: String
    var hasDog: Bool
    var hasKid: Bool
    var adminID: String
    
    init(groupName: String, date:Int, time:Int, repeats:String, duration:String, location:String, hasDog: Bool, hasKid: Bool, adminID: String) {
        self.groupName = groupName
        self.date = date
        self.time = time
        self.repeats = repeats
        self.duration = duration
        self.location = location
        self.hasDog = hasDog
        self.hasKid = hasKid
        self.adminID = adminID
    }
}
