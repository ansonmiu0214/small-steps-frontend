//
//  CreateGroupTVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

import Eureka

class CreateGroupVC: FormViewController {
    
    var group: Group? = nil
    
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
        
        var newGroup: Group = Group(groupName: valuesDict["groupName"] as! String,
                                    date: valuesDict["date"] as! Int,
                                    time: valuesDict["time"] as! Int,
                                    repeats: valuesDict["repeat"] as! String as! String,
                                    duration: valuesDict["duration"] as! String,
                                    location: valuesDict["location"] as! String,
                                    hasDog: (valuesDict["hasDog"] != nil),
                                    hasKid: (valuesDict["hasKid"] != nil),
                                    adminID: UIDevice.current.identifierForVendor!.uuidString)
        print("Group created \(newGroup.groupName)")
    }
}

//class CreateGroupTVC: UITableViewController {
//
//    enum ProfileSections: Int {
//        case Profile = 0,
//        Bio, // new section
//        Info,
//        Friends
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Uncomment the following line to preserve selection between presentations
//        // self.clearsSelectionOnViewWillAppear = false
//
//        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//        // self.navigationItem.rightBarButtonItem = self.editButtonItem
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 2
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//
//        cell.textLabel?.text = "Test"
//
//        return cell
//    }
//
//
//}
