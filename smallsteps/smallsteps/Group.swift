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
    var datetime: Date
    var repeats: String
    var duration: Date
    var location: String
    var hasDog: Bool
    var hasKid: Bool
    var adminID: String
    
    init(groupName: String, datetime:Date, repeats:String, duration:Date, location:String, hasDog: Bool, hasKid: Bool, adminID: String) {
        self.groupName = groupName
        self.datetime = datetime
        self.repeats = repeats
        self.duration = duration
        self.location = location
        self.hasDog = hasDog
        self.hasKid = hasKid
        self.adminID = adminID
    }

}
