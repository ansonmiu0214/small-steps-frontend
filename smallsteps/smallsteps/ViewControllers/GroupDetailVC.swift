//
//  GroupDetailVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 11/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import CoreLocation

class GroupDetailVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let detailsCell = tableView.dequeueReusableCell(withIdentifier: "groupDetailCell", for: indexPath) as! GroupDetailTableViewCell
        var locationCell = tableView.dequeueReusableCell(withIdentifier: "meetingLocationCell", for: indexPath) as! MeetingLocationTableViewCell
        
        getGroupsByUUID(){ userGroups in
            switch indexPath.section {
                
            case 0:
                //Group name
                
                detailsCell.groupNameLabel.text = userGroups[currGroup].groupName
                
                //Convert from datetime to string
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d yyyy, h:mm a"
                let stringDate: String = dateFormatter.string(from: userGroups[currGroup].datetime)
                detailsCell.meetingTimeLabel.text = stringDate
                
                //Duration
                let dateFormatter2: DateFormatter = DateFormatter()
                dateFormatter2.dateFormat = "hh"
                let hours: String = dateFormatter2.string(from: userGroups[currGroup].duration)
                dateFormatter2.dateFormat = "mm"
                let mins: String = dateFormatter2.string(from: userGroups[currGroup].duration)
                
                if (hours == "") {
                    detailsCell.durationLabel.text = "\(mins) minutes walk"
                } else if (hours == "01") {
                    detailsCell.durationLabel.text = "\(hours) hour \(mins) minutes walk"
                } else {
                    detailsCell.durationLabel.text = "\(hours) hours \(mins) minutes walk"
                }
            case 1:
                //Meeting location
                print("meeting group loc: lat = \(userGroups[currGroup].latitude), long = \(userGroups[currGroup].longitude)")
                locationCell = tableView.dequeueReusableCell(withIdentifier: "meetingLocationCell", for: indexPath) as! MeetingLocationTableViewCell
                locationCell.showLocation(location: CLLocation(latitude: Double(userGroups[currGroup].latitude)!, longitude: Double(userGroups[currGroup].longitude)!))
                
            default: break
                
            }
        }
        
        if indexPath.section == 0 {
            return detailsCell
        } else {
            return locationCell
        }
    }
    
    
    
    //        var groupName: String
    //        var datetime: Date
    //        var repeats: String
    //        var duration: Date
    //        var latitude: String
    //        var longitude: String
    //        var hasDog: Bool
    //        var hasKid: Bool
    //        var adminID: String
    //        var isWalking: Bool
    //        var groupId: String
    
}

