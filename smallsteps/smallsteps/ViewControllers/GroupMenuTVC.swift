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

var currGroupId: Int = -1
var globalUserGroups: [Int:Group] = [:]

func parseGroupsFromJSON(res: DataResponse<Any>) -> [Group] {
  var parsedGroups: [Group] = []
  if let jsonVal = res.result.value {
    let jsonVar = JSON(jsonVal)
    for (_, item) in jsonVar {
      parsedGroups.append(createGroupFromJSON(item: item))
    }
  }
  return parsedGroups
}

func getGroupsByUUID(completion: @escaping ([Group]) -> Void) {
  DispatchQueue(label: "GetUserGroups", qos: .background).async {
    let query = queryBuilder(endpoint: "groups", params: [("device_id", UUID)])
    Alamofire.request(query, method: .get).responseJSON { response in
      let userGroups = parseGroupsFromJSON(res: response)
      
      globalUserGroups = [:]
      for group in userGroups {
        globalUserGroups[Int(group.groupId)!] = group
      }
      
      completion(userGroups)
    }
  }
}

class GroupMenuTVC: UITableViewController {
  
  //  var userGroups: [Group] = []
  
  var sections = ["Created", "Joined"]
  var userGroups: [[Group]] = [[], []]
  
  func refreshTable(userGroups: [Group]) {
    // Set field with user groups from API
    self.userGroups[0] = userGroups.filter { $0.adminID.trimmingCharacters(in: .whitespaces) == UUID }
    self.userGroups[1] = userGroups.filter { $0.adminID.trimmingCharacters(in: .whitespaces) != UUID }
    
    // Refersh table data
    self.tableView.reloadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    getGroupsByUUID(completion: refreshTable)
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return self.sections[section]
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return sections.count
    //    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.userGroups[section].count
    //    return userGroups.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Create an object of the dynamic cell "PlainCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: "groupMenuCell", for: indexPath)
    let group = userGroups[indexPath.section][indexPath.row]
    cell.textLabel?.text = group.groupName
    
    // Create label
    let fontSize: CGFloat = 14
    let countBadge = UILabel()
    countBadge.font = UIFont(name: "System", size: fontSize)
    countBadge.textAlignment = .center
    countBadge.textColor = .white
    countBadge.backgroundColor = .red
    countBadge.text = String(group.numberOfPeople)
    
    // Set frame to be circular
    var frame = countBadge.frame
    frame.size.height = 20
    frame.size.width = (group.numberOfPeople < 10) ? 20 : 25
    countBadge.frame = frame
    countBadge.layer.cornerRadius = frame.size.height / 2.0
    countBadge.clipsToBounds = true
    
    // Show label
    cell.accessoryView = countBadge
    cell.accessoryType = .none
    
    // Return the configured cell
    return cell
  }
  
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.delete) {
      let groupToDelete = userGroups[indexPath.section][indexPath.row]
      
      let deleteURL = queryBuilder(endpoint: "groups", params: [("walker_id", UUID), ("group_id", groupToDelete.groupId)])
      
      let loadingPanel = buildLoadingOverlay(message: "Deleting you from '\(groupToDelete.groupName)'...")
      present(loadingPanel, animated: true) {
        // Make request
        Alamofire.request(deleteURL, method: .delete).response { response in
          loadingPanel.dismiss(animated: true) {
            getGroupsByUUID(completion: self.refreshTable)
          }
        }
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let group = self.userGroups[indexPath.section][indexPath.row]
    currGroupId = Int(group.groupId)!
    performSegue(withIdentifier: "menuToDetail", sender: self)
  }
  
  
}
