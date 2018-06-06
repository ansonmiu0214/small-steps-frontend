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

var groups: [Group] = [Group(groupName: "BOBOBO", datetime: Date(), repeats: "yes", duration: Date(), latitude: "51.5101", longitude: "-0.1342", hasDog: true, hasKid: false, adminID: "123456789009876543211234567890098765")]

class AllGroupsTVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups?latitude=51.4989&longitude=-0.1790", method: .get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { (responseData) -> Void in
                if((responseData.result.value) != nil) {
                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                        for (_, item) in swiftyJsonVar{
                            
                            for (label, value) in item {
                                print("\(label) : \(value)")
                            }
//                            print(item)
                             //print(item["name"].stringValue)
                        }
//                      for jsonVar in swiftyJsonVar{
//                          let resData = jsonVar["name"].stringValue
//                          print(resData)
//                    }
                    }

                }
        }
        
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        //return 1
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)
        //cell.textLabel?.text = groups[indexPath.row].groupName
        return cell
    }


}
