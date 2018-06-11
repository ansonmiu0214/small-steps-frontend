//
//  GroupMenuViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 04/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

import Alamofire
import SwiftyJSON

var myIndex = 0

class GroupMenuTVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    static func loadYourGroups(){
        print("LOAAADING GROUPS!!!!!!!!!!!!")
        let yourGroupParams: Parameters = [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            ]
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .get, parameters: yourGroupParams, encoding: URLEncoding.default)
            .responseJSON { (responseData) -> Void in
                if((responseData.result.value) != nil) {
                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                        for (_, item) in swiftyJsonVar{
                            let newGroup: Group = ViewController.createGroupFromJSON(item: item)
                            if (!userGroups.contains(newGroup)) {
                                userGroups.append(newGroup)
                            }
                            print("THE GROUP NAME IS: \(item["name"].string)")
                        }
                    }
                    
                }
        }
        
    }
    
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Groups"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch section {
//            case 0:
//                // Create New Group section
//                return 1
//            case 1:
//                // Your Groups section
//                return yourGroups.count
//            case 2:
//                // See All Groups section
//                return 1
//            default:
//                return 0
//        }
        return userGroups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create an object of the dynamic cell "PlainCell"

        let cell = self.tableView.dequeueReusableCell(withIdentifier: "groupMenuCell", for: indexPath)
        // Depending on the section, fill the textLabel with the relevant text
//        switch indexPath.section {
//            case 0:
//                cell.textLabel?.text = ""
//            case 1:
//                // Your Groups section
//
//            case 2:
//                // See All Groups section
//                print("hi")
//            default:
//                print("hi")
//        }

        cell.textLabel?.text = userGroups[indexPath.row].groupName
        // Return the configured cell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            userGroups.remove(at: indexPath.row)
            //ADD REMOVING FROM DATABASE
            
            
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        myIndex = indexPath.row
        performSegue(withIdentifier: "menuToDetail", sender: self)
    }
    


}
