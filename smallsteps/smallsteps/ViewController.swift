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
import StompClientLib

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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleGroupSelection {
  var selectedPin:MKPlacemark? = nil
  var currGroupId: String = "-1"
  
  @IBOutlet var map: MKMapView!
  
  var resultSearchController:UISearchController? = nil
  
  let manager = CLLocationManager()
  
  var isButtonClick: Bool = false
  
  var allGroups: [Group] = []
  var userGroups: [Group] = []
  var pinToGroup: [Int: Group] = [:]
  
  
  var socketClient = StompClientLib()
  let subscriptionURL = "/topic/confluence"
  let destinationURL = "/app/confluence"
  let registrationURL = "http://146.169.45.120:8080/smallsteps/ws"
  //  let subscriptionURL = "/topic/frontEnd"
  //let registrationURL = "http://146.169.45.120:8080/smallsteps/ws"
  //  let destinationURL = "/app/backEnd"
  //  var deviceIDAppend = "/-1"
  var deviceIDAppend = "/\(UIDevice.current.identifierForVendor!.uuidString)"
  //var adminIDAppend = "-1"
  
  func registerSocket(){
    let url = NSURL(string: registrationURL)
    
    socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url! as URL) , delegate: self as StompClientLibDelegate)
  }
  
  func alertAdmin(adminId:String){
    print("messaging")
    var location = manager.location?.coordinate
    
    var msg: String
    if let lat = location?.latitude {
      if let long = location?.longitude{
        msg = """
        {"lat": \(lat),
        "long": \(long)
        }
        """
      } else{
        msg = """
        {"lat": \(lat),
        "long": -0.1790
        }
        """
      }
    } else{
      msg = """
      {"lat": 51.4989,
      "long": -0.1790
      }
      """
    }
    
    let newDestinationURL = "\(destinationURL)/\(adminId)"
    print("destination is: " + newDestinationURL)
    let newSubscriptionURL = "\(subscriptionURL)\(deviceIDAppend)"
    print("sunsvription is: " + newSubscriptionURL)
    //socketClient.sendJSONForDict(dict: msg as AnyObject, toDestination: destinationURL)
    socketClient.sendMessage(message: msg, toDestination: newDestinationURL, withHeaders: nil, withReceipt: newSubscriptionURL)
  }
  
  @IBAction func message(_ sender: Any) {
    print("messaging")
    var location = manager.location?.coordinate
    
    var msg: String
    if let lat = location?.latitude {
      if let long = location?.longitude{
        msg = """
        {"lat": \(lat),
        "long": \(long)
        }
        """
      } else{
          msg = """
          {"lat": \(lat),
          "long": -0.1790
          }
          """
        }
    } else{
      msg = """
      {"lat": 51.4989,
      "long": -0.1790
      }
      """
    }
    
    let newDestinationURL = "\(destinationURL)\(deviceIDAppend)"
    let newSubscriptionURL = "\(subscriptionURL)\(deviceIDAppend)"
    
    //socketClient.sendJSONForDict(dict: msg as AnyObject, toDestination: destinationURL)
    socketClient.sendMessage(message: msg, toDestination: newDestinationURL, withHeaders: nil, withReceipt: newSubscriptionURL)
  }
  
  // On new location data
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location = locations.last as! CLLocation
    
    let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    self.map.setRegion(region, animated: true)
    
    //    if groups.count == 0 {
    //      let myLocation = locations[0]
    //      let span = MKCoordinateSpanMake(0.01, 0.01)
    //      let region: MKCoordinateRegion = MKCoordinateRegion(center: myLocation.coordinate, span: span)
    //      map.setRegion(region, animated: false)
    //    }
  }
  
  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    // TODO update groups shown with respect to changed regions
  }
  
  func setUpGroupData(completion: (() -> Void)? = nil) {
    var location = manager.location?.coordinate
    if location == nil{
      location = CLLocationCoordinate2DMake(51.4989, -0.1790)
    }
    getGroups(center: location!) { [unowned self] allGroups in
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
      var location = self.manager.location?.coordinate
      if location == nil{
        location = CLLocationCoordinate2DMake(51.4989, -0.1790)
      }
      let region = MKCoordinateRegion(center: location!, span: span)
      self.map.setRegion(region, animated: true)
    }
    
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    if isButtonClick {
      isButtonClick = !isButtonClick
      getRoute()
    }
    
    registerSocket()
    
    super.viewDidLoad()
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
  
  //used by group detail
  func getRoute() {
    let directionRequest = MKDirectionsRequest()
    directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (manager.location?.coordinate.latitude)!, longitude: (manager.location?.coordinate.longitude)!)))
    directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(globalUserGroups[currGroup].latitude)!, longitude: Double(globalUserGroups[currGroup].longitude)!)))
    directionRequest.transportType = .walking
    let directions = MKDirections(request: directionRequest)
    directions.calculate { (response, error) in
      guard let directionResponse = response else {
        if let error = error {
          print("We have an error getting the right directions \(error.localizedDescription)")
        }
        return
      }
      
      let route = directionResponse.routes[0]
      self.map.add(route.polyline, level: .aboveRoads)
      
      let rect = route.polyline.boundingMapRect
      self.map.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
    }
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = UIColor.red
    renderer.lineWidth = 5.0
    return renderer
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let pointAnnot = view.annotation as? LocationPointer{
      print("tapped on pointer: \(pointAnnot.groupId) with name: \(pointAnnot.title)")
      currGroupId = pointAnnot.groupId
    }
  }
  
  func createPinFromGroup(group: Group){
    var subtitle = "Meeting Time: \(dateToString(datetime: group.datetime))"
    subtitle += "\nDuration: \(getHoursMinutes(time: group.duration))"
    
    if group.hasDog { subtitle += "\nHas dogs" }
    if group.hasKid { subtitle += "\nHas kids" }
    if let placemark = group.placemark { subtitle += "\nMeeting Place: \(placemark.name!)" }
    
    print("the group when creaintg pin is: \(group)")
    let discipline = group.isWalking ? "In Progress" : "Not Started"
    let coordinate = CLLocationCoordinate2DMake(Double(group.latitude)!, Double(group.longitude)!)
    let annotation = LocationPointer(title: group.groupName, subtitle: subtitle, discipline: discipline, coordinate: coordinate, groupId: group.groupId, group: group)
    
    map.addAnnotation(annotation)
  }
  
  func selectAnnotation(group: Group) {
    // Filter location pointers only
    let annotations: [LocationPointer] = map.annotations.filter({ $0 is LocationPointer }) as! [LocationPointer]
    
    // Show annotation
    if let annotation = annotations.filter({ $0.group! == group }).first {
      map.selectAnnotation(annotation, animated: true)
    }
  }
  
  func getAdminFromGroup(groupId:String, completion: @escaping((String)->()) ){
    DispatchQueue(label: "Get AdminId", qos: .background).async {
      let params: Parameters = [
        "group_id": groupId
      ]
      
      Alamofire.request("\(SERVER_IP)/groups/admin", method: .get, parameters: params)
        .response { response in
          if let data = response.data, let id = String(data: data, encoding: .utf8) {
            completion(id)
          }
      }
    }
  }
  
  @objc func meetUp(){
    //TODO: fix the group
    print("meeting up with group: \(currGroupId)")
    getAdminFromGroup(groupId: currGroupId){ adminId in
      print(adminId)
      //self.adminIDAppend = "/\(adminId)"
      self.alertAdmin(adminId: adminId)
    }
    //TODO: subscribe to the group admin's channel
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
        infoButton.setTitleColor(#colorLiteral(red: 0.768627451, green: 0.3647058824, blue: 0.4980392157, alpha: 1), for: .normal)
        if(locPointAnnotation.discipline == "In Progress"){
          infoButton.setTitle("Meet Up", for: .normal)
          infoButton.addTarget(self, action: #selector(self.meetUp), for: .touchUpInside)

        } else{
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
          infoButton.addTarget(self, action: #selector(self.joinGroup(_:)), for: .touchUpInside)
        }
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

  
  //Fits all pins on the map to the map view
  func fitAll(showGroups: Bool) {
    var zoomRect = MKMapRectNull;
    //print(map.annotations)
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
  
}

extension ViewController: StompClientLibDelegate{
  func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, withHeader header: [String : String]?, withDestination destination: String) {
    print("> Destination : \(destination)")
    print("> JSON Body : \(String(describing: jsonBody))")
  }
  
  func stompClientJSONBody(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
    print("> DESTINATION : \(destination)")
    print("> String JSON BODY : \(String(describing: jsonBody!))")
  }
  
  func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
    print("> Receipt : \(receiptId)")
  }
  
  func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
    print("> Error Send : \(String(describing: message))")
  }
  
  func serverDidSendPing() {
    print("> Server ping")
  }
  
  func stompClientDidConnect(client: StompClientLib!) {
    print("> Socket is connected")
    // Stomp subscribe will be here!
    
    let ack = "ack_\(destinationURL)" // It can be any unique string
    let subsId = subscriptionURL // It can be any unique string
    let header = ["destination": destinationURL, "ack": ack, "id": subsId]
    let newURL = "\(subscriptionURL)\(deviceIDAppend)"
    print("i am subscribed toL " + newURL)
    socketClient.subscribeWithHeader(destination: newURL, withHeader: header)
  }
  
  func stompClientDidDisconnect(client: StompClientLib!) {
    print("> Socket is Disconnected")
    socketClient.unsubscribe(destination: subscriptionURL)
  }
  
  func stompClientWillDisconnect(client: StompClientLib!, withError error: NSError) {
  }
}
