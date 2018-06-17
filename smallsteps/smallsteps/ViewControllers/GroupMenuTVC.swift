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

class GroupMenuTVC: UITableViewController {
  
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
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.userGroups[section].count
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
