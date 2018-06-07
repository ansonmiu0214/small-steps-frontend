//
//  GroupMenuViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 04/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit


class GroupMenuTVC: UITableViewController {

    //let sections = ["Create A New Group", "Your Groups", "See All Groups"]
    let yourGroups = ["Huxley Walkers", "abc123"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
        return yourGroups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create an object of the dynamic cell "PlainCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupMenuCell", for: indexPath)
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
        cell.textLabel?.text = yourGroups[indexPath.row]
        // Return the configured cell
        return cell
    }
    


}
