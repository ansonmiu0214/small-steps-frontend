//
//  AllGroupsTVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


 var groups: [Group] = []
//var groups: [Group] = [Group(groupName: "BOBOBO", datetime: Date(), repeats: "yes", duration: Date(), latitude: "51.4989", longitude: "-0.1790", hasDog: true, hasKid: false, adminID: "123456789009876543211234567890098765", isWalking: true, groupId: "19"), Group(groupName: "BOBOBOsasdfsdf", datetime: Date(), repeats: "yes", duration: Date(), latitude: "51.5110", longitude: "-0.1318", hasDog: true, hasKid: false, adminID: "123456789009876543211234517890098765", isWalking: false, groupId: "20")]

class AllGroupsTVC: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    static func loadGroups(completion: @escaping () -> Void){
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups?latitude=51.4989&longitude=-0.1790", method: .get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { (responseData) -> Void in
                if((responseData.result.value) != nil) {
                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                        for (_, item) in swiftyJsonVar{
                            //Convert JSON to string to datetime
                            let dateFormatterDT: DateFormatter = DateFormatter()
                            dateFormatterDT.dateFormat = "yyyy-MM-dd hh:mm:ss"
                            let newDate: Date = dateFormatterDT.date(from: item["time"].string!)!
                            
                            //Convert JSON to string to duration
                            let dateFormatterDur: DateFormatter = DateFormatter()
                            dateFormatterDur.dateFormat = "hh:mm"
                            print("THE DURATION IS :" + item["duration"].string!)
                            //let newDuration: Date = dateFormatterDur.date(from: item["duration"].string!)!
                            
                            //Add new group to group array
                            groups.append(Group(groupName: item["name"].string!,
                                                datetime: newDate,
                                                repeats: "yes",
                                                duration: Date(),
                                                latitude: item["location_latitude"].string!,
                                                longitude: item["location_longitude"].string!,
                                                hasDog: item["has_dogs"].bool!,
                                                hasKid: item["has_kids"].bool!,
                                                adminID: item["admin_id"].string!,
                                                isWalking: item["is_walking"].bool!))
                            //                            for (label, value) in item {
                            //                                print("\(label) : \(value)")
                            //                            }
                            //                            print(item)
                            //print(item["name"].stringValue)
                        }
                        //                      for jsonVar in swiftyJsonVar{
                        //                          let resData = jsonVar["name"].stringValue
                        //                          print(resData)
                        //                    }
                    }
                    
                }
                
                for item in groups {
                    print("THE GROUP NAMES: " + item.groupName)
                }
                completion()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)
        cell.textLabel?.text = groups[indexPath.row].groupName
        return cell
    }


}
