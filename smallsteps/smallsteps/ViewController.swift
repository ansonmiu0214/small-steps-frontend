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

struct SenderResponse: Decodable{
  let sender: String
  
  enum CodingKeys: String, CodingKey {
    case sender
  }
}

struct LocationResponse: Decodable{
  let lat: String
  let long: String
  let senderID: String
  enum CodingKeys: String, CodingKey{
    case lat
    case long
    case senderID
  }
}

struct Response: Decodable{
  let response:Bool
  let latitude: String?
  let longitude: String?
  let confluenceLat: String?
  let confluenceLong: String?
  
  enum CodingKeys: String, CodingKey{
    case response
    case latitude
    case longitude
    case confluenceLat
    case confluenceLong
  }
}

protocol HandleGroupSelection {
  func selectAnnotation(group: Group)
}

func getDeviceOwner(deviceID:String, completion: @escaping (String) -> Void) {
  DispatchQueue(label: "Get Device Owner", qos: .background).async {
    let params: Parameters = [
      "device_id": deviceID,
    ]
    
    Alamofire.request("\(SERVER_IP)/walker/name", method: .get, parameters: params)
      .responseJSON { response in
        if let data = response.data, let name = String(data: data, encoding: .utf8) {
          completion(name.trimmingCharacters(in: .whitespaces))
        }
    }
  }
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
  var confluenceLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.5109208, longitude: -0.1377691)
  
  var socketClient = StompClientLib()
  let subscriptionURL = "/topic/confluence"
  let initDestinationURL = "/app/request"
  let locDestinationURL = "/app/confluence"
  let responseDestinationURL = "/app/response"
  //let registrationURL = "http://localhost:8080/ws"
  let registrationURL = "http://146.169.45.120:8080/smallsteps/ws"
  let deviceIDAppend = UIDevice.current.identifierForVendor!.uuidString

  var confluenceGroupId = "-1"
  var pendingConfluenceAlert: UIAlertController?
  var confluencePoint: MKPointAnnotation?

  var otherConfluenceID: String?
  
  func registerSocket(){
    let url = NSURL(string: registrationURL)
    
    socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url! as URL) , delegate: self as StompClientLibDelegate)
  }
  
  func requestAdminPermission(adminId:String){
      print("asking permission")
      let msg = """
      {"sender":"\(deviceIDAppend)"}
      """
      let newDestinationURL = "\(self.initDestinationURL)/\(adminId)"
      //socketClient.sendJSONForDict(dict: msg as AnyObject, toDestination: destinationURL)
      self.socketClient.sendMessage(message: msg, toDestination: newDestinationURL, withHeaders: nil, withReceipt: nil)
  }
  
  func respondToRequest(requesterId:String, didAccept:Bool){
    print("confirming request")
    var lat: Double
    var long: Double
    if let location = manager.location{
      lat = location.coordinate.latitude
      long = location.coordinate.longitude
    } else{
      lat = 51.4989
      long = -0.1790
    }
    print("sending the coordinates: \(lat) and \(long)")

    let msg = """
    {"response":\(didAccept),
    "latitude": "\(lat)",
    "longitude": "\(long)"
    }
    """
    
    let newDestinationURL = "\(self.responseDestinationURL)/\(requesterId)"
    self.socketClient.sendMessage(message: msg, toDestination: newDestinationURL, withHeaders: nil, withReceipt: nil)
  }
  
  func sendLocToUser(userId:String){
    print("messaging")
    var lat: Double
    var long: Double
    if let location = manager.location{
      lat = location.coordinate.latitude
      long = location.coordinate.longitude
    } else{
      lat = 51.4989
      long = -0.1790
    }

    let msg = """
        {"lat": "\(lat)",
        "long": "\(long)",
        "senderID": "\(deviceIDAppend)"
        }
        """

    let newDestinationURL = "\(locDestinationURL)/\(userId)"
    print("destination is: " + newDestinationURL)
    print("the message is: \(msg)")
    socketClient.sendMessage(message: msg, toDestination: newDestinationURL, withHeaders: nil, withReceipt: nil)
  }
  
  // On new location data

  func locationManager(_ manager: CLLocationManager, didUpdateUserLocation locations: [CLLocation]) {
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
      
      //self.addOrUpdateConfluence(location: (self.manager.location?.coordinate)!)
      
    }
    
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    if isGroupDetailButtonClick {
      isGroupDetailButtonClick = !isGroupDetailButtonClick
      getRoute()
    }
    
    if isConfluenceButtonClick {
      isConfluenceButtonClick = !isConfluenceButtonClick
      addConfluencePoint(location: confluenceLocation)
    }
    
    registerSocket()
    
    // Initialise visual effect view
    fxView.isHidden = true
    pinDetailView.layer.cornerRadius = 5
    
    view.autoresizesSubviews = true
    fxView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTap)))
    super.viewDidLoad()
  }
  
  @objc func dismissOnTap() {
    map.deselectAnnotation(activeAnnotation, animated: false)
    deinitialisePinDetailView()
  }
  
  func initialisePinDetailView(group: Group) {
    // Set up the panel
    detailTitle.text = group.groupName
    detailDescription.text = group.description
    detailTimings.text = "\(dateToString(datetime: group.datetime))"
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
  
  @IBAction func closePinDetailView(_ sender: Any) {
    map.deselectAnnotation(activeAnnotation, animated: false)
    deinitialisePinDetailView()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }
  
  fileprivate func setAndCreateConfluence() {
    let viewController = LocationPickerController(success: {
      [unowned self] (coordinate: CLLocationCoordinate2D) -> Void in
      //self?.locationLabel.text = "".appendingFormat("%.4f, %.4f",
      //coordinate.latitude, coordinate.longitude)
      //self?.addOrUpdateConfluence(location: coordinate)
      self.confluenceLocation = coordinate
      print("WE GETTTTTT BEFORE \(self.confluenceLocation)")
      
    })
    let navigationController = UINavigationController(rootViewController: viewController)
    self.addOrUpdateOtherLoc(location: self.confluenceLocation)
    self.present(navigationController, animated: true, completion: pinConfluence)
    print("WE GETTTTTT AFTER \(confluenceLocation)")
  }
  

  
  func pinConfluence() {
    addConfluencePoint(location: confluenceLocation)
  }
   
    @IBAction func addConfluenceBtn(_ sender: Any) {
        addConfluencePoint(location: confluenceLocation)
    }
  
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
      
//      let rect = route.polyline.boundingMapRect
//      self.map.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
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
    var subtitle = "Meeting Time: \(dateToString(datetime: group.datetime))"
    subtitle += "\nDuration: \(getHoursMinutes(time: group.duration))"
    
    if group.hasDog { subtitle += "\nHas dogs" }
    if group.hasKid { subtitle += "\nHas kids" }
    
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
            completion(id.trimmingCharacters(in: .whitespaces))
          }
      }
    }
  }
  
  @objc func meetUp(_ sender: UIButton){
    //TODO: fix the group
    confluenceGroupId = String(sender.tag)
    print("meeting up with group: \(confluenceGroupId)")
    getAdminFromGroup(groupId: confluenceGroupId){ [unowned self] adminId in
      print(adminId)
      self.requestAdminPermission(adminId: adminId)
      
      let pendingAlert = buildLoadingOverlay(message: "Waiting for response...")
      self.pendingConfluenceAlert = pendingAlert
      self.present(pendingAlert, animated: true, completion: nil)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [unowned self] in
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
  
  //------------------------CONFLUENCE------------------------
  
  //Adds the location of other to the map
  func addConfluencePoint(location: CLLocationCoordinate2D) {
    if let confluence = confluencePoint{
      print("confluence was already added. Updating instead")
      updateLoc(confluencePoint: confluence, newLocation: location)
    } else{
      confluencePoint = MKPointAnnotation()
      confluencePoint?.coordinate = location
      confluencePoint?.title = "Confluence Point"
      print("THE LOCATION OF CONFLUENCE IS: \(location)")
      map.addAnnotation(confluencePoint!)
    }
  }
  
  func addOrUpdateOtherLoc(location: CLLocationCoordinate2D) {
    if let confluence = confluencePoint{
      print("confluence was already added. Updating instead")
      updateLoc(confluencePoint: confluence, newLocation: location)
    } else{
      confluencePoint = MKPointAnnotation()
      confluencePoint?.coordinate = location
      confluencePoint?.title = "Other Person"
      
      map.addAnnotation(confluencePoint!)
    }
  }
  
  //Updates confluence point annotation on the map
  func updateLoc(confluencePoint: MKPointAnnotation, newLocation: CLLocationCoordinate2D) {
    map.removeAnnotation(confluencePoint)
    confluencePoint.coordinate = newLocation
    //confluencePoint.changeLocationTo(newLocation)
    map.addAnnotation(confluencePoint)
  }
  
  func confluenceAlert(requesterId:String) {
    getDeviceOwner(deviceID: requesterId){ name in

    let alert = UIAlertController(title: "Confluence Request", message: "Would you like to meet with \(name)?", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default){ _ in
      print("accepted")
      //self.setAndCreateConfluence()
      self.respondToRequest(requesterId: requesterId, didAccept: true)
      self.otherConfluenceID = requesterId
    })
    alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default){_ in
      print("declined")
      self.respondToRequest(requesterId: requesterId, didAccept: false)
    })
    self.present(alert, animated: true, completion: nil)
    }
  }
  
  func confluenceDeclinedAlert(){
    let alert = UIAlertController(title: "Confluence Declined", message: "Sorry, \(confluenceGroupId) has declined your request to join...", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
    
    self.present(alert, animated: true, completion: nil)

  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~CONFLUENCE~~~~~~~~~~~~~~~~~~~~~~~~
  
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
//    let jsonOutput = JSON(jsonBody!)
//    print(jsonOutput.type)
    let data = jsonBody?.data(using: .utf8)
   // print(jsonOutput)
    if let senderResponse = try? JSONDecoder().decode(SenderResponse.self, from: data!){
      // Someone else asking to join YOUR group
        print(senderResponse.sender)
        self.confluenceAlert(requesterId: senderResponse.sender)
      
    } else if let locationResponse = try? JSONDecoder().decode(LocationResponse.self, from: data!){
      // SENDING LOCATION BACK AND FORTH
      let coordinate = CLLocationCoordinate2D(latitude: Double(locationResponse.lat)!, longitude: Double(locationResponse.long)!)
      print(coordinate)
      addOrUpdateOtherLoc(location: coordinate)
    } else if let response = try? JSONDecoder().decode(Response.self, from: data!){
      // You getting a response from SOMEONE ELSE
      
      self.pendingConfluenceAlert?.dismiss(animated: true) { [unowned self] in
        self.pendingConfluenceAlert = nil
        if response.response{
          print("WOOO HOOOO WE'RE JOIN A GROUP")
         let location = CLLocationCoordinate2D(latitude: Double(response.latitude!)!, longitude: Double(response.longitude!)!)
          print("the admin is at lat: \(response.latitude) and longL \(response.longitude)")
         // let location = CLLocationCoordinate2D(latitude: 51.4989, longitude: -0.179)
          self.addOrUpdateOtherLoc(location: location)
          
          //Send your location to admin
          print("sending location to group: \(self.confluenceGroupId)")

          self.getAdminFromGroup(groupId: self.confluenceGroupId){ adminId in
            print(adminId)
            self.otherConfluenceID = adminId
            self.sendLocToUser(userId: adminId)
          }
        } else{
          print("awwwww you were declined")
          self.confluenceDeclinedAlert()
        }
      }
    } else {
      print("Should not get here")
      print()
    }
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

    let newURL = "\(subscriptionURL)/\(deviceIDAppend)"
    //print("i am subscribed toL " + newURL)
    socketClient.subscribe(destination: newURL)
    
  }
  
  func stompClientDidDisconnect(client: StompClientLib!) {
    print("> Socket is Disconnected")
    socketClient.unsubscribe(destination: subscriptionURL)
  }
  
  func stompClientWillDisconnect(client: StompClientLib!, withError error: NSError) {
  }
}
