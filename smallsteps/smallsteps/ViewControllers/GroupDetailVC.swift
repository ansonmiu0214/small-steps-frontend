import UIKit
import CoreLocation
import MapKit

class GroupDetailVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var meetingTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var meetingMap: MKMapView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var joinGroupBtn: UIButton!
    
    let dropPin = MKPointAnnotation()
    let manager = CLLocationManager()
    
    override func viewDidLoad() {

        self.meetingMap.delegate = self
        
        groupNameLabel.text = globalUserGroups[currGroup].groupName
            
        //Convert from datetime to string
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d yyyy, h:mm a"
        let stringDate: String = dateFormatter.string(from: globalUserGroups[currGroup].datetime)
        meetingTimeLabel.text = stringDate
            
        //Duration
        let dateFormatter2: DateFormatter = DateFormatter()
        dateFormatter2.dateFormat = "hh"
        let hours: String = dateFormatter2.string(from: globalUserGroups[currGroup].duration)
        dateFormatter2.dateFormat = "mm"
        let mins: String = dateFormatter2.string(from: globalUserGroups[currGroup].duration)
            
        if (hours == "") {
            durationLabel.text = "\(mins) minutes walk"
        } else if (hours == "01") {
            durationLabel.text = "\(hours) hour \(mins) minutes walk"
        } else {
            durationLabel.text = "\(hours) hours \(mins) minutes walk"
        }

        showLocation(location: CLLocation(latitude: Double(globalUserGroups[currGroup].latitude)!, longitude: Double(globalUserGroups[currGroup].longitude)!))
        
        addGesture()
        
        descriptionLabel.text = globalUserGroups[currGroup].description
    }
    
    
    func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(GroupDetailVC.showActionSheet))
        view.addGestureRecognizer(tap)
    }

    @objc func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let routeToMeetingPoint = UIAlertAction(title: "Find Route to Meeting Point", style: .default) { action in
            self.getRoute()
        }

        actionSheet.addAction(cancel)
        actionSheet.addAction(routeToMeetingPoint)

        present(actionSheet, animated: true, completion: nil)
    }
    
    func getRoute() {
        self.performSegue(withIdentifier: "meetingRoute", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? ViewController {
            destVC.isButtonClick = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.001, 0.001)
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(globalUserGroups[currGroup].latitude)!, Double(globalUserGroups[currGroup].longitude)!)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        meetingMap.setRegion(region, animated: true)
        
        
        self.meetingMap.showsUserLocation = true
        meetingMap.delegate = self
    }
    
    func showLocation(location:CLLocation) {
        let orgLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        dropPin.coordinate = orgLocation
        meetingMap!.addAnnotation(dropPin)
        self.meetingMap?.setRegion(MKCoordinateRegionMakeWithDistance(orgLocation, 500, 500), animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    

}
