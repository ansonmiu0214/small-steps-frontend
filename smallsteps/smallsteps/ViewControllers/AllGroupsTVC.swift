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
import CoreLocation

var groups: [Group] = []
var myGroups: [Group] = []

func createGroupFromJSON(item: JSON) -> Group{
  //Convert JSON to string to datetime
  let dateFormatterDT: DateFormatter = DateFormatter()
  dateFormatterDT.dateFormat = "yyyy-MM-dd hh:mm:ss"
  let newDate: Date = dateFormatterDT.date(from: item["time"].string!)!
  
  //Convert JSON to string to duration
  let dateFormatterDur: DateFormatter = DateFormatter()
  dateFormatterDur.dateFormat = "hh:mm"
  //print("THE DURATION IS :" + item["duration"].string!)
  //let newDuration: Date = dateFormatterDur.date(from: item["duration"].string!)!
  
  //Add new group to group array
  let newGroup: Group = Group(groupName: item["name"].string!,
                              datetime: newDate,
                              repeats: "yes",
                              duration: Date(),
                              latitude: item["location_latitude"].string!,
                              longitude: item["location_longitude"].string!,
                              hasDog: item["has_dogs"].bool!,
                              hasKid: item["has_kids"].bool!,
                              adminID: item["admin_id"].string!,
                              isWalking: item["is_walking"].bool!,
                              groupId: item["id"].string!)
  return newGroup
}

class AllGroupsTVC: UITableViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
  }
  
  //    static func createGroupFromJSON(item: JSON) -> Group{
  //        //Convert JSON to string to datetime
  //        let dateFormatterDT: DateFormatter = DateFormatter()
  //        dateFormatterDT.dateFormat = "yyyy-MM-dd hh:mm:ss"
  //        let newDate: Date = dateFormatterDT.date(from: item["time"].string!)!
  //
  //        //Convert JSON to string to duration
  //        let dateFormatterDur: DateFormatter = DateFormatter()
  //        dateFormatterDur.dateFormat = "hh:mm"
  //        //print("THE DURATION IS :" + item["duration"].string!)
  //        //let newDuration: Date = dateFormatterDur.date(from: item["duration"].string!)!
  //
  //        //Add new group to group array
  //        let newGroup: Group = Group(groupName: item["name"].string!,
  //                                    datetime: newDate,
  //                                    repeats: "yes",
  //                                    duration: Date(),
  //                                    latitude: item["location_latitude"].string!,
  //                                    longitude: item["location_longitude"].string!,
  //                                    hasDog: item["has_dogs"].bool!,
  //                                    hasKid: item["has_kids"].bool!,
  //                                    adminID: item["admin_id"].string!,
  //                                    isWalking: item["is_walking"].bool!,
  //                                    groupId: item["id"].string!)
  //        return newGroup
  //    }
  
  //    static func loadGroups(completion: @escaping () -> Void){
  //        var latitude: String
  //        var longitude: String
  //        if let location = CLLocationManager().location?.coordinate{
  //            latitude = String(location.latitude)
  //            longitude = String(location.longitude)
  //        } else{
  //            latitude = "51.4989"
  //            longitude = "-0.1790"
  //        }
  //
  //        let localGroupsParams: Parameters = [
  //            "latitude": latitude,
  //            "longitude": longitude
  //        ]
  //
  //        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .get, parameters: localGroupsParams, encoding: URLEncoding.default)
  //            .responseJSON { (responseData) -> Void in
  //                if((responseData.result.value) != nil) {
  //                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
  //                        for (_, item) in swiftyJsonVar{
  //                            groups.append(createGroupFromJSON(item: item))
  //                        }
  //                    }
  //                }
  //                completion()
  //        }
  //    }
  
  static func loadUserGroups(completion: @escaping () -> Void){
    let deviceGroupsParams: Parameters = [
      "device_id":UIDevice.current.identifierForVendor!.uuidString
    ]
    
    Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .get, parameters: deviceGroupsParams, encoding: URLEncoding.default)
      .responseJSON { (responseData) -> Void in
        if((responseData.result.value) != nil) {
          if let swiftyJsonVar = try? JSON(responseData.result.value!) {
            for (_, item) in swiftyJsonVar{
              groups.append(createGroupFromJSON(item: item))
            }
          }
          
          let uuid = UIDevice.current.identifierForVendor!
          Alamofire.request("http://146.169.45.120:8080/smallsteps/groups?device_id=\(uuid)", method: .get, encoding: JSONEncoding.default).responseJSON { response -> Void in
            if let val = response.result.value {
              if let jsonVal = try? JSON(val) {
                myGroups =  []
                for (_, item) in jsonVal {
                  myGroups.append(createGroupFromJSON(item: item))
                }
              }
            }
            
            completion()
          }
        }
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
