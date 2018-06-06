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
        //let doneButton = UIBarButtonItem(barButtonSystemItem: nil, target: self, action: #selector(tapButton))
        let nextButton = UIBarButtonItem(image: UIImage(named: "walking"), style: .plain, target: self, action: #selector(CreateGroupVC.createGroup))
        self.navigationItem.rightBarButtonItem = nextButton
        
        super.viewDidLoad()
        form +++ Section("Group Details")
            <<< TextRow(){ row in
                row.tag = "groupName"
                row.title = "Name"
                row.placeholder = "Enter group name here"
            }
            +++ Section("Meeting Date and Time")
            <<< DateTimeRow(){
                $0.tag = "datetime"
                $0.title = "Date and Time"
                $0.value = Date()
            }
            <<< ActionSheetRow<String>() {
                $0.tag = "repeat"
                $0.title = "Repeat"
                $0.selectorTitle = "Pick a Day"
                $0.options = ["Daily"]
                $0.value = "Daily"    // initially selected
            }
            <<< TimeRow() {
                $0.tag = "duration"
                $0.title = "Estimated Duration"
                let date = Calendar.current.date(bySettingHour: 0, minute: 30, second: 0, of: Date())! //initial value
                $0.value = date

            }
//            +++ Section("Meeting Point")
//            <<< TextRow() { row in
//                row.tag = "location"
//                row.title = "Location"
//                //TODO!!!!!
//            }
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
    
    @objc func setLocation() {
        performSegue(withIdentifier: "setLocation", sender: self)
    }

    
    @objc func createGroup() {
        let valuesDict = form.values()
        print(type(of: valuesDict))
        
        let newGroup: Group = Group(groupName: valuesDict["groupName"] as! String,
                                    datetime: valuesDict["datetime"] as! Date,
                                    repeats: valuesDict["repeat"] as! String ,
                                    duration: valuesDict["duration"] as! Date,
                                    location: "",
                                    hasDog: form.rowBy(tag: "hasDog")!.value!,
                                    hasKid: form.rowBy(tag: "hasKid")!.value!,
                                    adminID: UIDevice.current.identifierForVendor!.uuidString)
        print("Group created \(newGroup.groupName)")

        
        //Create the walker parameters
        let groupParams: Parameters = [
            "name": newGroup.groupName,
            "time": removeTimezone(datetime: newGroup.datetime),
            "admin_id": newGroup.adminID,
            "location_latitude": "51.498899999999999",
            "location_longitude": "-0.178999999999999992",
            "duration": getHoursMinutesSeconds(time: newGroup.duration),
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
    
    func removeTimezone(datetime: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let newDate: String = dateFormatter.string(for: datetime)!
        print("THE NEW DATE IS: \(newDate)")
        return newDate
    }
    
    func getHoursMinutesSeconds(time: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let newTime: String = dateFormatter.string(for: time)!
        print("THE NEW TIME IS: \(newTime)")

        return newTime
    }
}

