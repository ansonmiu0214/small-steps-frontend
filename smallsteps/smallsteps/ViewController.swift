//
//  ViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import AVFoundation
import SwiftyJSON

var yourGroups: [Group] = []

protocol HandleMapSearch {
  func dropPinZoomIn(placemark:MKPlacemark)
}

func getGroups(center: CLLocationCoordinate2D, completion: @escaping ([Group]) -> Void) -> Void {
  DispatchQueue(label: "Get Groups", qos: .background).async {
    let params: Parameters = [
      "latitude": String(center.latitude),
      "longitude": String(center.longitude)
    ]
    
    Alamofire.request("\(SERVER_IP)/groups", method: .get, parameters: params)
      .responseJSON { response in
        let allGroups = parseGroupsFromJSON(res: response)
        completion(allGroups)
    }
  }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleMapSearch{
  var selectedPin:MKPlacemark? = nil
  var currGroupId: String = "-1"
  @IBOutlet var map: MKMapView!
  
  var resultSearchController:UISearchController? = nil
  var userId: Int = 0
  
  let manager = CLLocationManager()
  
  var allGroups: [Group] = []
  var userGroups: [Group] = []
  
  // On new location data
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if groups.count == 0 {
      let myLocation = locations[0]
      let span = MKCoordinateSpanMake(0.01, 0.01)
      let region: MKCoordinateRegion = MKCoordinateRegion(center: myLocation.coordinate, span: span)
      map.setRegion(region, animated: false)
    }
  }
  
  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    // TODO update groups shown with respect to changed regions
  }
  
  override func viewWillAppear(_ animated: Bool) {
    getGroups(center: (manager.location?.coordinate)!) { [unowned self] allGroups in
      getGroupsByUUID { userGroups in
        // Set fields
        self.allGroups = allGroups
        self.userGroups = userGroups
      
        // Reset annotations
        self.map.removeAnnotations(self.map.annotations)
        self.allGroups.forEach(self.createPinFromGroup)
        
        // Set up MapView
        self.map.delegate = self
        self.map.showsUserLocation = true
        
        // Set up CoreLocation manager
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestWhenInUseAuthorization()
        self.manager.startUpdatingLocation()
        
        // Zoom into your location
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegion(center: self.manager.location!.coordinate, span: span)
        self.map.setRegion(region, animated: true)
      }
    }
    
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    //Location Search Table Setup
    let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
    resultSearchController = UISearchController(searchResultsController: locationSearchTable)
    resultSearchController?.searchResultsUpdater = locationSearchTable
    
    locationSearchTable.handleMapSearchDelegate = self
    
    //Search Bar Setup
    let searchBar = resultSearchController!.searchBar
    searchBar.sizeToFit()
    searchBar.placeholder = "Set Your Destination"
    navigationItem.titleView = resultSearchController?.searchBar
    resultSearchController?.hidesNavigationBarDuringPresentation = false
    resultSearchController?.dimsBackgroundDuringPresentation = true
    definesPresentationContext = true
    
    //Set the map view in locationSearchTable
    locationSearchTable.map = map
    
    super.viewDidLoad()
  }
  
  static func createGroupFromJSON(item: JSON) -> Group {
    //Convert JSON to string to datetime
    let dateFormatterDT: DateFormatter = DateFormatter()
    dateFormatterDT.dateFormat = "yyyy-MM-dd hh:mm:ss"
    let newDate: Date = dateFormatterDT.date(from: item["time"].string!)!
    
    //Convert JSON to string to duration
    let dateFormatterDur: DateFormatter = DateFormatter()
    dateFormatterDur.dateFormat = "hh:mm"
    //print("THE DURATION IS :" + item["duration"].string!)
    //let newDuration: Date = dateFormatterDur.date(from: item["duration"].string!)!
    
    //Add new group to group array
    let newGroup: Group = Group(groupName: item["name"].string!,
                                datetime: newDate,
                                repeats: "yes",
                                duration: Date(),
                                latitude: item["location_latitude"].string!,
                                longitude: item["location_longitude"].string!,
                                hasDog: item["has_dogs"].bool!,
                                hasKid: item["has_kids"].bool!,
                                adminID: item["admin_id"].string!,
                                isWalking: item["is_walking"].bool!,
                                groupId: item["id"].string!)
    return newGroup
  }
  
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @objc func getDirections(){
    let request = MKDirectionsRequest()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = MKMapItem(placemark: selectedPin!)
    request.requestsAlternateRoutes = false
    request.transportType = .walking
    let directions = MKDirections(request: request)
    
    directions.calculate(completionHandler: {(response, error) in
      
      if error != nil {
        print("Could not obtain directions!")
      } else {
        self.showRoute(response!)
      }
    })
  }
  
  func showRoute(_ response: MKDirectionsResponse) {
    map.removeOverlays(map.overlays)
    print("showing route!")
    for route in response.routes {
      map.add(route.polyline,
              level: MKOverlayLevel.aboveRoads)
    }
    self.fitAll(showGroups: false)
  }
  
  func mapView(_ mapView: MKMapView, rendererFor
    overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = UIColor.red
    renderer.lineWidth = 5.0
    return renderer
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
    // Return on user location
    if annotation is MKUserLocation { return nil }
    
    let reuseId = "Pin"
    let pinView = LocationPointerView(annotation: annotation, reuseIdentifier: reuseId)
    pinView.canShowCallout = true
    print(annotation.title ?? "no title!!")
    let directionButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
    directionButton.setBackgroundImage(#imageLiteral(resourceName: "walking"), for: .normal)
    directionButton.addTarget(self, action: #selector(self.getDirections), for: .touchUpInside)
    
    pinView.leftCalloutAccessoryView = directionButton
    if let locPointAnnotation = annotation as? LocationPointer{
      if(locPointAnnotation.discipline != ""){
        let infoButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 70, height: 50)))
        infoButton.setTitle("Join", for: .normal)
        print("locpointannotgroup: \(locPointAnnotation)")
        if let grp = locPointAnnotation.group {
          print("group is: \(grp.groupName)")
          if userGroups.contains(grp) {
            infoButton.setTitle("Joined", for: .normal)
            infoButton.isEnabled = false
          }
        }
        infoButton.setTitleColor(#colorLiteral(red: 0.768627451, green: 0.3647058824, blue: 0.4980392157, alpha: 1), for: .normal)
        infoButton.addTarget(self, action: #selector(self.joinGroup), for: .touchUpInside)
        pinView.rightCalloutAccessoryView = infoButton
      }
    }
    
    let subtitleView = UILabel()
    subtitleView.font = subtitleView.font.withSize(12)
    subtitleView.numberOfLines = 4
    subtitleView.text = annotation.subtitle!
    pinView.detailCalloutAccessoryView = subtitleView
    
    return pinView
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
  {
    selectedPin = MKPlacemark(coordinate: (view.annotation?.coordinate)!)
    print("currently selected pin at: \(String(describing: selectedPin))")
    if let locPointAnnotation = view.annotation as? LocationPointer{
      if locPointAnnotation.discipline != ""{
        currGroupId = (locPointAnnotation.groupId)
        print("groupId = \(currGroupId)")
      }
    }
    
    if let annotationTitle = view.annotation?.title
    {
      print("User tapped on annotation with title: \(annotationTitle!)")
      
    }
  }
  
  func createPinFromGroup(group: Group){
    var subtitle = "Meeting Time: \(dateToString(datetime: group.datetime))"
    subtitle += "\nDuration ~ \(getHoursMinutes(time: group.duration))"
    if(group.hasDog){
      subtitle += "\nHas Dogs"
    }
    if(group.hasKid){
      subtitle += "\nHas Kids"
    }
    
    let discipline = group.isWalking ? "In Progress" : "Not Started"
    let coordinate = CLLocationCoordinate2DMake(Double(group.latitude)!, Double(group.longitude)!)
    let annotation = LocationPointer(title: group.groupName, subtitle: subtitle, discipline: discipline, coordinate:  coordinate, groupId: group.groupId, group: group)
    map.addAnnotation(annotation)
  }
  
  func dropPinZoomIn(placemark:MKPlacemark){
    //Clear previous pin and overlay
    map.removeOverlays(map.overlays)
    
    if(selectedPin != nil){
      for annotation in map.annotations {
        if let pointAnnotation = annotation as? LocationPointer{
          if (pointAnnotation.discipline != "In Progress" ||
            pointAnnotation.discipline != "Not Started"){
            map.removeAnnotation(pointAnnotation)
          }
        } else{
          map.removeAnnotation(annotation)
        }
      }
    }
    // save the pin so we can find directions to it later
    selectedPin = placemark
    
    var subtitle = ""
    if let city = placemark.locality,
      let state = placemark.administrativeArea {
      subtitle = "\(city), \(state)"
    }
    let annotation = LocationPointer(title: placemark.name!, subtitle: subtitle, discipline: "", coordinate: placemark.coordinate)
    map.addAnnotation(annotation)
    
    let span = MKCoordinateSpanMake(0.03, 0.03)
    let region = MKCoordinateRegionMake(placemark.coordinate, span)
    map.setRegion(region, animated: true)
  }
  
  //Fits all pins on the map to the map view
  func fitAll(showGroups: Bool) {
    var zoomRect = MKMapRectNull;
    print(map.annotations)
    for annotation in map.annotations {
      if showGroups
        || annotation is MKUserLocation
        || (annotation.coordinate.latitude == selectedPin?.coordinate.latitude
          && annotation.coordinate.longitude == selectedPin?.coordinate.longitude) {
        let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
        let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.05, 0.05);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
      }
    }
    map.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(70, 70, 70, 70), animated: true)
  }
  
  func callPopUp(identifier: String){
    let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as! JoinGroupPopupVC
    self.addChildViewController(popOverVC)
    popOverVC.view.frame = self.view.frame
    self.view.addSubview(popOverVC.view)
    popOverVC.didMove(toParentViewController: self)
  }
  
  
  @objc func joinGroup(){
    print("joining group with id: \(currGroupId)")
    
    let joinGroupParams: Parameters = [
      "walker_id": UIDevice.current.identifierForVendor!.uuidString,
      "group_id": currGroupId
    ]
    
    print(UIDevice.current.identifierForVendor!.uuidString)
    
    print(joinGroupParams)
    
    //PUT request JSON to the server
    Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .put, parameters: joinGroupParams, encoding: URLEncoding.default)
      .response {response in
        
        print(response.request)
        print(response.response)
        print(response.response?.statusCode ?? "no response!")
        if let optStatusCode = response.response?.statusCode{
          switch optStatusCode {
          case 200...300:
            print("successfully joined the group!!")
            self.callPopUp(identifier: "popup")
          default:
            print("error")
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
          }
          
          // TODO delete later
          let uuid = UIDevice.current.identifierForVendor!
          Alamofire.request("http://146.169.45.120:8080/smallsteps/groups?device_id=\(uuid)", method: .get, encoding: JSONEncoding.default).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
              if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                myGroups = []
                for (_, item) in swiftyJsonVar{
                  myGroups.append(ViewController.createGroupFromJSON(item: item))
                  print(item)
                }
              }
            }
            
            // reset map annotations and add them again
            self.map.removeAnnotations(self.map.annotations)
            
            groups.forEach { group in self.createPinFromGroup(group: group)}
          }
          // END (TODO)
          
        }
    }
  }
  
  func dateToString(datetime: Date) -> String {
    let timeFormatter: DateFormatter = DateFormatter()
    timeFormatter.dateFormat = "H:mm"
    let newTime: String = timeFormatter.string(for: datetime)!
    
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    let newDate: String = dateFormatter.string(for: datetime)!
    return "\(newTime) \(newDate)"
  }
  
  func getHoursMinutes(time: Date) -> String {
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "H"
    let newHour: String = dateFormatter.string(for: time)!
    dateFormatter.dateFormat = "m"
    let newMinute: String = dateFormatter.string(from: time)
    if newHour == "0"{
      return "\(newMinute) minutes"
    }
    var hour: String
    if(newHour == "1"){
      hour = "\(newHour) hour"
    }
    hour = "\(newHour) hours"
    if(newMinute == "0"){
      return hour
    }
    
    return "\(hour) and \(newMinute) minutes"
  }
  
}
