//
//  CreateGroupTVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

import Eureka
import Alamofire
class CreateGroupVC: FormViewController {
    
    override func viewDidLoad() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapButton))
        self.navigationItem.rightBarButtonItem = doneButton
        
        super.viewDidLoad()
        form +++ Section("Group Details")
            <<< TextRow(){ row in
                row.tag = "groupName"
                row.title = "Name"
                row.placeholder = "Enter group name here"
            }
            +++ Section("Meeting Date and Time")
            <<< DateRow(){
                $0.tag = "date"
                $0.title = "Date"
                $0.value = Date()
            }
            <<< TimeRow(){
                $0.tag = "time"
                $0.title = "Time"
                $0.value = Date()
            }
            <<< ActionSheetRow<String>() {
                $0.tag = "repeat"
                $0.title = "Repeat"
                $0.selectorTitle = "Pick a Day"
                $0.options = ["Every Day",
                              "Every Monday",
                              "Every Tuesday",
                              "Every Wednesday",
                              "Every Thursday",
                              "Every Friday",
                              "Every Saturday",
                              "Every Sunday"]
                $0.value = "Every Day"    // initially selected
            }
            <<< ActionSheetRow<String>() {
                $0.tag = "duration"
                $0.title = "Estimated Duration"
                $0.selectorTitle = "Pick a Duration"
                $0.options = ["15 mins",
                              "30 mins",
                              "45 mins",
                              "1 hour"]
                $0.value = "15 mins"    // initially selected
            }
            +++ Section("Meeting Point")
            <<< TextRow() { row in
                row.tag = "location"
                row.title = "Location"
                //TODO!!!!!
            }
            +++ Section("Details")
            <<< SwitchRow() { row in
                row.tag = "hasDog"
                row.title = "Dogs"
            }
            <<< SwitchRow() { row in
                row.tag = "hasKids"
                row.title = "Kids"
        }
    }
    
    @objc func tapButton() {
        let valuesDict = form.values()
        print(type(of: valuesDict))
        
        let newGroup: Group = Group(groupName: valuesDict["groupName"] as! String,
                                    date: valuesDict["date"] as! Date,
                                    time: valuesDict["time"] as! Date,
                                    repeats: valuesDict["repeat"] as! String ,
                                    duration: valuesDict["duration"] as! String,
                                    location: "",
                                    hasDog: (valuesDict["hasDog"] != nil),
                                    hasKid: (valuesDict["hasKid"] != nil),
                                    adminID: UIDevice.current.identifierForVendor!.uuidString)
        print("Group created \(newGroup.groupName)")

        
        //Create the walker parameters
        let groupParams: Parameters = [
            //"id": "3",
            "name": newGroup.groupName,
            "time": "\(newGroup.date) \(newGroup.time)",
            "admin_id": newGroup.adminID,
            "location_latitude": "51.498899999999999",
            "location_longitude": "-0.178999999999999992",
            "duration": newGroup.duration, //TODO: fix format
            "has_dogs": newGroup.hasDog,
            "has_kids": newGroup.hasKid
        ]


        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .post, parameters: groupParams, encoding: JSONEncoding.default)
            .response {response in
                print(response.response?.statusCode ?? "no response!")
                print(groupParams)
        }
    }
}

