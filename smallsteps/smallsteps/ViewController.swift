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
import LocationPickerController

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleGroupSelection {
  var selectedPin:MKPlacemark? = nil
  var currentGroupId: String = "-1"
  
  @IBOutlet var map: MKMapView!
  
  // Pin details view
  @IBOutlet var pinDetailView: UIView!
  var effect: UIVisualEffect!
  var activeAnnotation: MKAnnotation? = nil
  @IBOutlet weak var fxView: UIVisualEffectView!
  @IBOutlet weak var detailTitle: UILabel!
  @IBOutlet weak var detailActions: UIButton!
  @IBOutlet weak var detailDescription: UITextView!
  @IBOutlet weak var detailTimings: UITextView!
  
  var resultSearchController:UISearchController? = nil
  
  let manager = CLLocationManager()
  
  var isGroupDetailButtonClick: Bool = false
  var isConfluenceButtonClick: Bool = false
  
  var allGroups: [Group] = []
  var userGroups: [Group] = []
  var pinToGroup: [Int: Group] = [:]
  
  // Confluence utils
  
  
  var socketClient = StompClientLib()
  let subscriptionURL = "/topic/confluence"
  let initDestinationURL = "/app/request"
  let locDestinationURL = "/app/confluence"
  let responseDestinationURL = "/app/response"
  //let registrationURL = "http://localhost:8080/ws"
  let registrationURL = "http://146.169.45.120:8080/smallsteps/ws"
  let deviceIDAppend = UIDevice.current.identifierForVendor!.uuidString
  
  var pendingConfluenceAlert: UIAlertController?
  
  var confluenceGroupId = "-1"
  var confluencePoint: MKPointAnnotation?
  var confluenceLocation: CLLocationCoordinate2D = DEFAULT_COORD
  
  var otherPersonWalkerId: String?
  var otherWalkerCoord: CLLocationCoordinate2D?
  var otherWalkerName: String?
  var otherWalkerMapAnnotation: MKPointAnnotation?
  
  
  var confluenceRoutes: [MKRoute] = []
  
  
  func registerSocket(){
    let url = NSURL(string: registrationURL)
    
    socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url! as URL) , delegate: self as StompClientLibDelegate)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setUpGroupData { [unowned self] in
      // Set up MapView
      self.map.delegate = self
      self.map.showsUserLocation = true
      
      // Set up CoreLocation manager
      self.manager.delegate = self
      self.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
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
      
      //self.addOrUpdateConfluence(location: (self.manager.location?.coordinate)!)
      
      if self.isGroupDetailButtonClick {
        self.isGroupDetailButtonClick = !self.isGroupDetailButtonClick
        self.getRoute()
      }
      
      if self.isConfluenceButtonClick {
        self.isConfluenceButtonClick = !self.isConfluenceButtonClick
        self.renderConfluencePoint()
        self.getDirections()
        self.respondToRequest(otherPersonId: self.otherPersonWalkerId!, didAccept: true)
      }
    }
    
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    registerSocket()
    
    // Initialise visual effect view
    fxView.isHidden = true
    pinDetailView.layer.cornerRadius = 5
    pinDetailView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.8, height: self.view.frame.height * 0.7)
    pinDetailView.center = self.view.center
    
    // Add dismiss-on-tap gesture recogniser
    fxView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTap)))
    super.viewDidLoad()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let currentLocation = locations.first!
    if let otherUserId = otherPersonWalkerId {
      if let otherCoord = otherWalkerCoord {
        let otherLat = otherCoord.latitude
        let otherLong = otherCoord.longitude
        
        let distance = currentLocation.distance(from: CLLocation(latitude: otherLat, longitude: otherLong))
        print("[#] Distance from other person: \(distance)")
        if distance < CONFLUENCE_THRESHOLD_IN_METRES {
          // Remove pins
          if let point = self.confluencePoint { self.map.removeAnnotation(point) }
          if let otherPoint = self.otherWalkerMapAnnotation { self.map.removeAnnotation(otherPoint) }
          self.map.removeOverlays(self.map.overlays)
          resetConfluenceVariables()
          
          let alert = UIAlertController(title: nil, message: "Confluence reached", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          present(alert, animated: true, completion: nil)
        } else {
          sendLocationToUser(otherUserId: otherUserId)
        }
      } else {
        sendLocationToUser(otherUserId: otherUserId)
      }
    }
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
        
        for group in self.allGroups {
          self.pinToGroup[Int(group.groupId)!] = group
        }
        
        // Reset annotations
        self.map.removeAnnotations(self.map.annotations)
        self.allGroups.forEach(self.createPinFromGroup)
        
        completion?()
      }
    }
  }
  
  @objc func dismissOnTap() {
    map.deselectAnnotation(activeAnnotation, animated: false)
    deinitialisePinDetailView()
  }
  
  @IBAction func closePinDetailView(_ sender: Any) {
    map.deselectAnnotation(activeAnnotation, animated: false)
    deinitialisePinDetailView()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @objc func getDirections(){
    let request = MKDirectionsRequest()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: confluenceLocation))
    request.requestsAlternateRoutes = false
    request.transportType = .walking
    let directions = MKDirections(request: request)
    
    directions.calculate { (response, error) in
      if error == nil {
        self.showRoute(response!)
      }
    }
  }
  
  func showRoute(_ response: MKDirectionsResponse) {
    map.removeOverlays(map.overlays)
    
    self.confluenceRoutes = response.routes
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
    directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(globalUserGroups[currGroupId]!.latitude)!, longitude: Double(globalUserGroups[currGroupId]!.longitude)!)))
    directionRequest.transportType = .walking
    let directions = MKDirections(request: directionRequest)
    directions.calculate { (response, error) in
      guard let directionResponse = response else {
        if let error = error {
          print("We have an error getting the right directions \(error.localizedDescription)")
        }
        return
      }
      
      let ALocation: CLLocation = CLLocation(latitude: (self.manager.location?.coordinate.latitude)!, longitude: (self.manager.location?.coordinate.longitude)!)
      let BLocation: CLLocation = CLLocation(latitude: Double(globalUserGroups[currGroupId]!.latitude)!, longitude: Double(globalUserGroups[currGroupId]!.longitude)!)
      let midPointLat = (ALocation.coordinate.latitude + BLocation.coordinate.latitude) / 2
      let midPointLong = (ALocation.coordinate.longitude + BLocation.coordinate.longitude) / 2
      let midPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: Double(midPointLat), longitude: Double(midPointLong))
      let dist: CLLocationDistance = ALocation.distance(from: BLocation)
      let region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(midPoint, 2 * dist, 2 * dist)
      let route = directionResponse.routes[0]
      self.map.add(route.polyline, level: .aboveRoads)
      self.map.setRegion(region, animated: true)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "setConfluence" {
      if let dstVC = segue.destination as? CreateConfluenceVC {
        dstVC.otherConfluenceID = otherPersonWalkerId
        dstVC.otherPerson = (otherWalkerName!, otherWalkerCoord!)
      }
    }
  }
  
  //Style and color of the route
  func mapView(_ mapView: MKMapView, rendererFor
    overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = self.view.tintColor
    renderer.lineWidth = 7.0
    return renderer
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let locationPointer = view.annotation as? LocationPointer {
      activeAnnotation = locationPointer
      initialisePinDetailView(group: locationPointer.group!)
    }
  }
  
  func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    deinitialisePinDetailView()
  }
  
  func createPinFromGroup(group: Group){
    var subtitle = "Meeting Time: \(prettyDateToString(date: group.datetime))"
    subtitle += "\nDuration: \(prettyDurationToString(time: group.duration))"
    
    if group.hasDog { subtitle += "\nHas dogs" }
    if group.hasKid { subtitle += "\nHas kids" }
    
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

  
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
    // Return on user location
    if annotation is MKUserLocation { return nil }
    
    if annotation is MKPointAnnotation {
      let annotationView = LocationPointerView(annotation: annotation, reuseIdentifier: "Pin")
      annotationView.markerTintColor = annotation.title!! == "Confluence" ? .red : .blue
      return annotationView
    }
    
    let reuseId = "Pin"
    let pinView = LocationPointerView(annotation: annotation, reuseIdentifier: reuseId)
    pinView.canShowCallout = true
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
          if let grp = locPointAnnotation.group {
            // Add entry to lookup dictionary for `tag -> group`
            
            infoButton.tag = Int(grp.groupId)!
            let tag = infoButton.tag
            pinToGroup[infoButton.tag] = grp
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
  
//  func callPopUp(identifier: String){
//    let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as! JoinGroupPopupVC
//    self.addChildViewController(popOverVC)
//    popOverVC.view.frame = self.view.frame
//    self.view.addSubview(popOverVC.view)
//    popOverVC.didMove(toParentViewController: self)
//  }
  
  func buildCompletionAlert(success: Bool, group: Group) -> UIAlertController {
    let title = success ? "Success!" : "Error occurred"
    let msg = success ? "You have joined \(group.groupName)" : "Please try again later."
    
    let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    return alert
  }
  
  @objc func meetUp(_ sender: UIButton){
    confluenceGroupId = String(sender.tag)
    getAdminFromGroup(groupId: confluenceGroupId){ [unowned self] adminId in
      self.otherPersonWalkerId = adminId
      self.requestAdminPermission(adminId: adminId)
      
      let pendingAlert = buildLoadingOverlay(message: "Waiting for response...")
      self.pendingConfluenceAlert = pendingAlert
      self.present(pendingAlert, animated: true, completion: nil)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + TIMEOUT_IN_SECS) { [unowned self] in
        if let alert = self.pendingConfluenceAlert {
          alert.dismiss(animated: true) {
            let group = self.pinToGroup[sender.tag]!
            let failureAlert = UIAlertController(title: "Request Timeout", message: "The group admin for \(group.groupName) did not respond to your confluence request.", preferredStyle: .alert)
            failureAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(failureAlert, animated: true, completion: nil)
          }
        }
      }
    }
  }
  
  @objc func joinGroup(_ sender: UIButton) {
    let tag = sender.tag
    let groupToJoin = pinToGroup[tag]!
    
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
}

// ~~~~~~~~~ StompClientLibDelegate
extension ViewController: StompClientLibDelegate{
  
  func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, withHeader header: [String : String]?, withDestination destination: String) {
    print("[Socket] stompClient: " + destination)
  }
  
  func stompClientJSONBody(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
    print("[Socket] stomClientJSONBody: " + destination)
    let data = jsonBody!.data(using: .utf8)!
    
    // Someone is asking to join your group
    if let senderResponse = try? JSONDecoder().decode(SenderResponse.self, from: data) {
      print("[Admin] received request from #\(senderResponse.sender.prefix(3)) to join your group...")
      
      let coordinate = CLLocation(latitude: Double(senderResponse.senderLat)!, longitude: Double(senderResponse.senderLong)!)
      self.confluenceRequestAlert(otherPersonId: senderResponse.sender, otherPersonLoc: coordinate)
      return
    }
    
    // Someone is sending you their location
    if let locationResponse = try? JSONDecoder().decode(LocationResponse.self, from: data){
      print("[#\(UUID.prefix(3))] received location data from #\(locationResponse.senderID.prefix(3))...")
      
      guard let _ = confluencePoint else { return }
      
      let otherLocation = CLLocation(latitude: Double(locationResponse.lat)!, longitude: Double(locationResponse.long)!)
      renderOtherPersonLocation(newLocation: otherLocation.coordinate)
      
      // Check for stopping condition
      if let myLocation = manager.location {
        let distance = myLocation.distance(from: otherLocation)
        print("[#] Distance from other person: \(distance)")
        if distance < CONFLUENCE_THRESHOLD_IN_METRES {
          
          let alert = UIAlertController(title: nil, message: "Confluence reached", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Remove pins
            if let point = self.confluencePoint { self.map.removeAnnotation(point) }
            if let otherPoint = self.otherWalkerMapAnnotation { self.map.removeAnnotation(otherPoint) }
            
            self.map.removeOverlays(self.map.overlays)
            
            self.resetConfluenceVariables()
          })
          
          present(alert, animated: true, completion: nil)
        }
      }
      
      return
    }
    
    // You previously submitted a confluence request and are receiving a response
    if let response = try? JSONDecoder().decode(Response.self, from: data) {
      self.pendingConfluenceAlert?.dismiss(animated: true) { [unowned self] in
        self.pendingConfluenceAlert = nil
        
        if response.response {
          // Confluence request accepted
          print("[Joiner] Confluence request accepted...")
          
          // Parse other person's location
          let location = CLLocationCoordinate2D(latitude: Double(response.latitude!)!, longitude: Double(response.longitude!)!)
          self.renderOtherPersonLocation(newLocation: location)
          
          // Parse confluence point
          self.confluenceLocation = CLLocationCoordinate2D(latitude: Double(response.confluenceLat!)!, longitude: Double(response.confluenceLong!)!)
          self.renderConfluencePoint()
          
          // Send your location to group admin
          print("[Joiner] Sending location to group admin")
          self.sendLocationToUser(otherUserId: self.otherPersonWalkerId!)
          
          // Show confluence accepted alert
          let acceptedAlert = UIAlertController(title: "Success!", message: "Confluence request accepted", preferredStyle: .alert)
          acceptedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          self.present(acceptedAlert, animated: true) {
            // Hide pin detail view
            self.map.deselectAnnotation(self.activeAnnotation, animated: false)
            self.deinitialisePinDetailView()
            
            // Show directions
            self.getDirections()
          }
        } else{
          print("[Joiner] Confluence request declined...")
          self.confluenceDeclinedAlert()
        }
      }

    } else {
      // Unknown JSON packet received
      print("[Socket] received unknown JSON: " + String(describing: jsonBody!))
    }
  }
  
  func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
    print("[Socket] receipt: " + receiptId)
  }
  
  func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
    print("[Socket] serverDidSendError: " + String(describing: message))
  }
  
  func serverDidSendPing() {
    print("[Socket] serverDidSendPing")
  }
  
  func stompClientDidConnect(client: StompClientLib!) {
    print("[Socket] stompClientDidConnect")
    socketClient.subscribe(destination: (subscriptionURL + "/" + UUID))
    
  }
  
  func stompClientDidDisconnect(client: StompClientLib!) {
    print("[Socket] stompClientWillDisconnect")
    socketClient.unsubscribe(destination: subscriptionURL)
  }
  
  func stompClientWillDisconnect(client: StompClientLib!, withError error: NSError) {
    print("[Socket] stompClientWillDisconnect")
  }
  
}

// ~~~~~~~~~ ConfluenceDelegate
extension ViewController: ConfluenceDelegate {
  
  func requestAdminPermission(adminId: String) {
    // Obtain current location
    let lat = manager.location?.coordinate.latitude ?? DEFAULT_LAT
    let long = manager.location?.coordinate.longitude ?? DEFAULT_LNG
    
    // Print debugging message
    print("[Joiner] Requesting admin #\(adminId) sending own coords (\(lat), \(long))...")
    
    // Compose request
    let permissionRequest = SenderResponse(sender: UUID, senderLat: String(lat), senderLong: String(long))
    let jsonRequest = try? JSONEncoder().encode(permissionRequest)
    let jsonMsg = String(data: jsonRequest!, encoding: .utf8)
    let dstUrl = initDestinationURL + "/" + adminId
    socketClient.sendMessage(message: jsonMsg!, toDestination: dstUrl, withHeaders: nil, withReceipt: nil)
  }

  func respondToRequest(otherPersonId: String, didAccept: Bool) {
    // Obtain current location
    let lat = manager.location?.coordinate.latitude ?? DEFAULT_LAT
    let long = manager.location?.coordinate.longitude ?? DEFAULT_LNG

    // Parse confluence location
    let confLat = confluencePoint?.coordinate.latitude ?? DEFAULT_LAT
    let confLong = confluencePoint?.coordinate.longitude ?? DEFAULT_LNG
    
    if didAccept { renderConfluencePoint() }
    
    // Print debugging message
    print("[Admin] Responding to user #\(otherPersonId.prefix(3)) with own coords (\(lat), \(long)) and confluence coords (\(confLat), \(confLong))...")
    
    // Compose response
    let confluenceResponse = Response(response: didAccept, latitude: String(lat), longitude: String(long), confluenceLat: String(confLat), confluenceLong: String(confLong))
    let jsonRequest = try? JSONEncoder().encode(confluenceResponse)
    let jsonMsg = String(data: jsonRequest!, encoding: .utf8)
    let dstUrl = responseDestinationURL + "/" + otherPersonId
    socketClient.sendMessage(message: jsonMsg!, toDestination: dstUrl, withHeaders: nil, withReceipt: nil)
  }
  
  func sendLocationToUser(otherUserId: String) {
    // Obtain current location
    let lat = manager.location?.coordinate.latitude ?? DEFAULT_LAT
    let long = manager.location?.coordinate.longitude ?? DEFAULT_LNG
    
    // Print debugging message
    print("[#\(UUID.prefix(3))] Responding to user #\(otherUserId.prefix(3)) with own coords (\(lat), \(long))...")
    
    // Compose response
    let locationResponse = LocationResponse(lat: String(lat), long: String(long), senderID: otherUserId)
    let jsonRequest = try? JSONEncoder().encode(locationResponse)
    let jsonMsg = String(data: jsonRequest!, encoding: .utf8)
    let dstUrl = locDestinationURL + "/" + otherUserId
    socketClient.sendMessage(message: jsonMsg!, toDestination: dstUrl, withHeaders: nil, withReceipt: nil)
  }
  
  func renderConfluencePoint() {
    if let confluence = confluencePoint {
      print("[#\(UUID.prefix(3))] updating confluence point...")
      
      map.removeAnnotation(confluence)
      confluence.coordinate = confluenceLocation
      map.addAnnotation(confluence)
    } else {
      print("[#\(UUID.prefix(3))] adding confluence point...")
      
      confluencePoint = MKPointAnnotation()
      confluencePoint?.coordinate = confluenceLocation
      confluencePoint?.title = "Confluence"
      map.addAnnotation(confluencePoint!)
    }
  }
  
  func renderOtherPersonLocation(newLocation: CLLocationCoordinate2D) {
    if let otherPerson = otherWalkerMapAnnotation {
      print("[#\(UUID.prefix(3))] updating other location point...")
      map.removeAnnotation(otherPerson)
      otherPerson.coordinate = newLocation
      map.addAnnotation(otherPerson)
    } else {
      print("[#\(UUID.prefix(3))] adding other location point...")
      otherWalkerMapAnnotation = MKPointAnnotation()
      otherWalkerMapAnnotation?.coordinate = newLocation
      otherWalkerMapAnnotation?.title = otherWalkerName ?? "Other Person"
      map.addAnnotation(otherWalkerMapAnnotation!)
    }
  }
  
  func confluenceRequestAlert(otherPersonId: String, otherPersonLoc: CLLocation) {
    otherWalkerCoord = otherPersonLoc.coordinate
    getDeviceOwner(deviceID: otherPersonId) { name in
      self.otherWalkerName = name
      
      // Look up placemark of other person's location
      CLGeocoder().reverseGeocodeLocation(otherPersonLoc) { (res, err) in
        let placename = res?[0].name ?? "(\(otherPersonLoc.coordinate.latitude), \(otherPersonLoc.coordinate.longitude))"
        
        print("[Admin] setting up confluence request alert...")
        // Set up confluence alert
        let title = "Confluence Request"
        let msg = "\(name) in \(placename) would like to join your group."
        
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { _ in
          print("[Admin] accepted confluence...")
          self.otherPersonWalkerId = otherPersonId
          self.performSegue(withIdentifier: "setConfluence", sender: nil)
        }
        
        let declineAction = UIAlertAction(title: "Decline", style: .default) { _ in
          print("[Admin] declined confluence...")
          self.respondToRequest(otherPersonId: otherPersonId, didAccept: false)
        }
        
        let confluenceAlert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        confluenceAlert.addAction(acceptAction)
        confluenceAlert.addAction(declineAction)
        
        self.present(confluenceAlert, animated: true, completion: nil)
      }
    }
  }
  
  func confluenceDeclinedAlert() {
    print("[Joiner] Displaying confluence declined...")
    
    let group = pinToGroup[Int(confluenceGroupId)!]!
    let title = "Confluence Declined"
    let msg = "The creator of \(group.groupName) has declined your request to meet up."
    
    // Reset variables
    resetConfluenceVariables()
    
    let declineAlert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    declineAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(declineAlert, animated: true, completion: nil)
  }
  
  func resetConfluenceVariables() {
    confluenceGroupId = "-1"
    confluencePoint = nil
    confluenceLocation = DEFAULT_COORD
    pendingConfluenceAlert = nil
    otherWalkerMapAnnotation = nil
    otherPersonWalkerId = nil
    otherWalkerCoord = nil
    otherWalkerName = nil
  }
  
}

// ~~~~~~~~~ PinViewDelegate
extension ViewController: PinViewDelegate {
  
  func initialisePinDetailView(group: Group) {
    // Set up the panel
    detailTitle.text = group.groupName
    detailDescription.text = group.description
    detailTimings.text = prettyDateToString(date: group.datetime)
    
    // Wire up action button depending on joined/meet/join
    detailActions.setTitle("Joined", for: .disabled)
    detailActions.tag = Int(group.groupId)!
    if userGroups.contains(group) {
      detailActions.isEnabled = false
    } else {
      detailActions.isEnabled = true
      if group.isWalking {
        detailActions.setTitle("Meet", for: .normal)
        detailActions.addTarget(self, action: #selector(self.meetUp(_:)), for: .touchUpInside)
      } else {
        detailActions.setTitle("Join", for: .normal)
        detailActions.addTarget(self, action: #selector(self.joinGroup(_:)), for: .touchUpInside)
      }
    }
    
    // First initialise to transparent
    pinDetailView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
    pinDetailView.alpha = 0
    
    // Animate introduction with "magic move"
    UIView.animate(withDuration: 0.4) {
      self.view.addSubview(self.pinDetailView)
      self.pinDetailView.center = self.view.center
      
      self.fxView.isHidden = false
      self.pinDetailView.alpha = 1
      self.pinDetailView.transform = CGAffineTransform.identity
    }
  }
  
  func deinitialisePinDetailView() {
    // Destroy view components
    detailTitle.text = nil
    detailDescription.text = nil
    detailTimings.text = nil
    
    UIView.animate(withDuration: 0.4, animations: {
      self.pinDetailView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
      self.pinDetailView.alpha = 0
      self.fxView.isHidden = true
      self.pinDetailView.removeFromSuperview()
    })
  }
  
}
