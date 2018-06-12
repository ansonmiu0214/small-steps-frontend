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

protocol HandleGroupSelection {
  func selectAnnotation(group: Group)
}

func getGroups(center: CLLocationCoordinate2D, completion: @escaping ([Group]) -> Void) {
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

func addWalkerToGroup(groupId: String, completion: @escaping (Bool) -> Void)  {
  DispatchQueue(label: "JoinRequest", qos: .background).async {
    let params: Parameters = [
      "group_id": groupId,
      "walker_id": UUID
    ]
    
    Alamofire.request("\(SERVER_IP)/groups", method: .put, parameters: params)
      .responseJSON { response in
        completion(response.response?.statusCode == HTTP_OK)
    }
  }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleGroupSelection{
  var selectedPin:MKPlacemark? = nil
  var currGroupId: String = "-1"
  @IBOutlet var map: MKMapView!
  
  var resultSearchController:UISearchController? = nil
  var userId: Int = 0
  
  let manager = CLLocationManager()
  
  var allGroups: [Group] = []
  var userGroups: [Group] = []
  var pinToGroup: [Int: Group] = [:]
  
  // On new location data
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

  }
  
  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    // TODO update groups shown with respect to changed regions
  }
  
  func setUpGroupData(completion: (() -> Void)? = nil) {
    getGroups(center: (manager.location?.coordinate)!) { [unowned self] allGroups in
      getGroupsByUUID { userGroups in
        // Set fields
        self.allGroups = allGroups
        self.userGroups = userGroups
        
        // Reset annotations
        self.pinToGroup = [:]
        self.map.removeAnnotations(self.map.annotations)
        self.allGroups.forEach(self.createPinFromGroup)
        
        completion?()
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setUpGroupData { [unowned self] in
      // Set up MapView
      self.map.delegate = self
      self.map.showsUserLocation = true
      
      // Set up CoreLocation manager
      self.manager.delegate = self
      self.manager.desiredAccuracy = kCLLocationAccuracyBest
      self.manager.requestWhenInUseAuthorization()
      self.manager.startUpdatingLocation()
      
      // Set up LocationSearchTable
      let locationSearchTable = self.storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
      locationSearchTable.groups = self.allGroups
      self.resultSearchController = UISearchController(searchResultsController: locationSearchTable)
      self.resultSearchController?.searchResultsUpdater = locationSearchTable
      
      locationSearchTable.handleMapSearchDelegate = self
      
      // Set up SearchBar
      let searchBar = self.resultSearchController!.searchBar
      searchBar.sizeToFit()
      searchBar.placeholder = "Search for groups"
      self.navigationItem.titleView = self.resultSearchController?.searchBar
      self.resultSearchController?.hidesNavigationBarDuringPresentation = false
      self.resultSearchController?.dimsBackgroundDuringPresentation = true
      self.definesPresentationContext = true

      // Zoom into your location
      let span = MKCoordinateSpanMake(0.01, 0.01)
      let region = MKCoordinateRegion(center: self.manager.location!.coordinate, span: span)
      self.map.setRegion(region, animated: true)
    }
    
    super.viewWillAppear(animated)
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
          // Add entry to lookup dictionary for `tag -> group`
          
          infoButton.tag = Int(grp.groupId)!
          let tag = infoButton.tag
          pinToGroup[infoButton.tag] = grp
          print("group is: \(grp.groupName)")
          if userGroups.contains(grp) {
            infoButton.setTitle("Joined", for: .normal)
            infoButton.isEnabled = false
          }
        }
        infoButton.setTitleColor(#colorLiteral(red: 0.768627451, green: 0.3647058824, blue: 0.4980392157, alpha: 1), for: .normal)
        infoButton.addTarget(self, action: #selector(self.joinGroup(_:)), for: .touchUpInside)
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
  
  func selectAnnotation(group: Group) {
    let annotations: [LocationPointer] = map.annotations.filter({ $0 is LocationPointer }) as! [LocationPointer]
    
    
    if let annotation = annotations.filter({ $0.group! == group }).first {
      map.selectAnnotation(annotation, animated: true)
    }
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
  
  func buildCompletionAlert(success: Bool, group: Group) -> UIAlertController {
    let title = success ? "Success!" : "Error occurred"
    let msg = success ? "You have joined \(group.groupName)" : "Please try again later."
    
    let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    return alert
  }
  
  @objc func joinGroup(_ sender: UIButton){
    let groupToJoin = pinToGroup[sender.tag]!
    
    // Show loading overlay
    let alert = buildLoadingOverlay(message: "Adding you to \(groupToJoin.groupName)...")
    present(alert, animated: true) { [unowned self] in
      // Submit request to server, dismiss alert on complete, show error alert on error
      addWalkerToGroup(groupId: groupToJoin.groupId) { isSuccess in
        alert.dismiss(animated: true) {
          let completionAlert = self.buildCompletionAlert(success: isSuccess, group: groupToJoin)
          self.present(completionAlert, animated: true, completion: nil)
          
          // Reload groups if success
          if isSuccess { self.setUpGroupData() }
        }
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
