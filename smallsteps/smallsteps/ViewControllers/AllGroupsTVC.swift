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
  // Format meeting time as date
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
  let newDate = dateFormatter.date(from: item["time"].string!)!
  
  // Format duration as date
  let durationFormatter = DateFormatter()
  durationFormatter.dateFormat = "hh:mm:ss"
  let duration = durationFormatter.date(from: item["duration"].string!)!

  return Group(groupName: item["name"].string!,
                datetime: newDate,
                repeats: "yes",
                duration: duration,
                latitude: item["location_latitude"].string!,
                longitude: item["location_longitude"].string!,
                hasDog: item["has_dogs"].bool!,
                hasKid: item["has_kids"].bool!,
                adminID: item["admin_id"].string!,
                isWalking: item["is_walking"].bool!,
                groupId: item["id"].string!)
}

class AllGroupsTVC: UITableViewController {
  
  override func viewDidLoad() {
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
    
    super.viewDidLoad()
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
