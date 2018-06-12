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
      completion(userGroups)
    }
  }
}

class GroupMenuTVC: UITableViewController {
  
  var userGroups: [Group] = []
  
  
  
  func refreshTable(userGroups: [Group]) {
    // Set field with user groups from API
    self.userGroups = userGroups
    
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
    return "Your Groups"
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return userGroups.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Create an object of the dynamic cell "PlainCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: "groupMenuCell", for: indexPath)
    cell.textLabel?.text = userGroups[indexPath.row].groupName
    
    // Return the configured cell
    return cell
  }

}
