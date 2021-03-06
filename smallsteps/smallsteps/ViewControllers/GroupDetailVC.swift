import UIKit
import CoreLocation
import MapKit

class GroupDetailVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
  @IBOutlet weak var groupNameLabel: UILabel!
  @IBOutlet weak var meetingTimeLabel: UILabel!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var meetingMap: MKMapView!
  @IBOutlet weak var descriptionLabel: UILabel!
  
  let group = globalUserGroups[currGroupId]!
  let dropPin = MeetingPointMarker(identifier: "meetingPoint", title: globalUserGroups[currGroupId]!.groupName, coordinate: CLLocationCoordinate2D(latitude: Double(globalUserGroups[currGroupId]!.latitude)!, longitude: Double(globalUserGroups[currGroupId]!.longitude)!))
  let manager = CLLocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.meetingMap.delegate = self
    
    // Set up label text
    groupNameLabel.text = group.groupName
    meetingTimeLabel.text = prettyDateToString(date: group.datetime)
    durationLabel.text = prettyDurationToString(time: group.duration)
    showLocation(location: CLLocation(latitude: Double(group.latitude)!, longitude: Double(group.longitude)!))
    
    descriptionLabel.text = group.description
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
      destVC.isGroupDetailButtonClick = true
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let span: MKCoordinateSpan = MKCoordinateSpanMake(0.001, 0.001)
    let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(group.latitude)!, Double(group.longitude)!)
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
