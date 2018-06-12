import UIKit
import CoreLocation
import MapKit

class GroupDetailVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var meetingTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var meetingMap: MKMapView!
    
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
        // Do any additional setup after loading the view.
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//        annotationView.isEnabled = true
//        annotationView.canShowCallout = true
//        let btn = UIButton(type: .detailDisclosure)
//        annotationView.rightCalloutAccessoryView = btn
//        return annotationView
//    }
//
//    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        let ac = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
//        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        let routeToMeetingPoint = UIAlertAction(title: "Find Route to Meeting Point", style: .default, handler: nil)
//
//        ac.addAction(cancel)
//        ac.addAction(routeToMeetingPoint)
//
//        present(ac, animated: true)
//    }
    
    
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
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (manager.location?.coordinate.latitude)!, longitude: (manager.location?.coordinate.longitude)!)))
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(globalUserGroups[currGroup].latitude)!, longitude: Double(globalUserGroups[currGroup].longitude)!)))
        directionRequest.transportType = .automobile
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {
                if let error = error {
                    print("We have an error getting the right directions \(error.localizedDescription)")
                }
                return
            }
            
            let route = directionResponse.routes[0]
            self.meetingMap.add(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.meetingMap.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    
    //MARK :- MapKit delegates
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
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
