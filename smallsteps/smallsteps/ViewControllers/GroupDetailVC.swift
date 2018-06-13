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
    
    let dropPin = MeetingPointMarker(identifier: "meetingPoint", title: globalUserGroups[currGroup].groupName, coordinate: CLLocationCoordinate2D(latitude: Double(globalUserGroups[currGroup].latitude)!, longitude: Double(globalUserGroups[currGroup].longitude)!))
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
        
        //addGesture()
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
        
        meetingMap!.addAnnotation(dropPin)
        self.meetingMap?.setRegion(MKCoordinateRegionMakeWithDistance(orgLocation, 500, 500), animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "meetingPoint"
        
        let pinView = MeetingPointMarkerView(annotation: annotation, reuseIdentifier: identifier)
        pinView.canShowCallout = true
        
        if annotation is MeetingPointMarker {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier: identifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
                
                let btn = UIButton(type: .detailDisclosure)
                btn.setTitle("Find Route", for: UIControlState.normal)
                annotationView.rightCalloutAccessoryView = btn
                
                return annotationView
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let meetingPoint = view.annotation as! MeetingPointMarker
        
//        let ac = UIAlertController(title: "Find Route to Meeting Point", message: "", preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "OK", style: .default))
//        present(ac, animated: true)
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let routeToMeetingPoint = UIAlertAction(title: "Find Route to Meeting Point", style: .default) { action in
            self.getRoute()
        }
        
        actionSheet.addAction(cancel)
        actionSheet.addAction(routeToMeetingPoint)
        
        present(actionSheet, animated: true, completion: nil)
    }

}
