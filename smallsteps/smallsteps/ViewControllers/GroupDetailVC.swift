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
        
        switch indexPath.section {
        case 0:
            //Group name
            detailsCell.groupNameLabel.text = globalUserGroups[currGroup].groupName
            
            //Convert from datetime to string
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy, h:mm a"
            let stringDate: String = dateFormatter.string(from: globalUserGroups[currGroup].datetime)
            detailsCell.meetingTimeLabel.text = stringDate
            
            //Duration
            detailsCell.durationLabel.text = "\(getHoursMinutes(time: globalUserGroups[currGroup].duration)) walk"
        case 1:
            //Meeting location
            locationCell = tableView.dequeueReusableCell(withIdentifier: "meetingLocationCell", for: indexPath) as! MeetingLocationTableViewCell
            locationCell.showLocation(location: CLLocation(latitude: Double(globalUserGroups[currGroup].latitude)!, longitude: Double(globalUserGroups[currGroup].longitude)!))
        default: break
            
            
        }
        
        if indexPath.section == 0 {
            return detailsCell
        } else {
            return locationCell
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
}
