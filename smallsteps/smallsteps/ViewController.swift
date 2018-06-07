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

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleMapSearch{
    var selectedPin:MKPlacemark? = nil
    var currGroupId: String = "-1"
    @IBOutlet var map: MKMapView!
    
    var resultSearchController:UISearchController? = nil
    var userId: Int = 0
    let manager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location = locations[0]
//        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
//        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
//        let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
//        map.setRegion(region, animated: true)
        fitAll(showGroups: true)
        self.map.showsUserLocation = true
        map.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let viewController = ViewController()
//        viewController.delegate = self
//        
        //MapKit Setup
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
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
        
        fitAll(showGroups: true)
        
        //Set the map view in locationSearchTable
        locationSearchTable.map = map
        map.removeAnnotations(map.annotations)
        
        AllGroupsTVC.loadGroups(){
            //Create pins from groups
            print("groups is: \(groups)")
            for group in groups{
                self.createPinFromGroup(group: group)
            }
        }
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
//            for step in route.steps {
//                print(step.instructions)
//            }
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
        if annotation is MKUserLocation {
            //so we don't modify the standard user location
            return nil
        }
        let reuseId = "Pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? LocationPointerView
        pinView = LocationPointerView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.canShowCallout = true
        print(annotation.title ?? "no title!!")
        let directionButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
        directionButton.setBackgroundImage(#imageLiteral(resourceName: "walking"), for: .normal)
        directionButton.addTarget(self, action: #selector(self.getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = directionButton
 
        if let locPointAnnotation = annotation as? LocationPointer{
            if(locPointAnnotation.discipline != ""){
                let infoButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50)))
                infoButton.setTitle("Join", for: .normal)
                infoButton.setTitleColor(#colorLiteral(red: 0.768627451, green: 0.3647058824, blue: 0.4980392157, alpha: 1), for: .normal)
                infoButton.addTarget(self, action: #selector(self.joinGroup), for: .touchUpInside)
                pinView?.rightCalloutAccessoryView = infoButton
            }
        }
        
        let subtitleView = UILabel()
        subtitleView.font = subtitleView.font.withSize(12)
        subtitleView.numberOfLines = 4
        subtitleView.text = annotation.subtitle!
        pinView?.detailCalloutAccessoryView = subtitleView
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        selectedPin = MKPlacemark(coordinate: (view.annotation?.coordinate)!)
        print("currently selected pin at: \(selectedPin)")
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
    
//    func createPinFromGroup(group: Group){
//        print("created a group")
//        var subtitle = "Meeting Time: \(dateToString(datetime: group.datetime))"
//        subtitle += "\nDuration ~ \(getHoursMinutes(time: group.duration))"
//        if(group.hasDog){
//            subtitle += "\nHas Dogs"
//        }
//        if(group.hasKid){
//            subtitle += "\nHas Kids"
//        }
//
//        let discipline = group.isWalking ? "In Progress" : "Not Started"
//
//        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(group.latitude)!, Double(group.longitude)!)
//        let annotation = LocationPointer(title: group.groupName, subtitle: subtitle, discipline: discipline, coordinate:  coordinate, groupId: group.groupId)
//        map.addAnnotation(annotation)
//    }
    
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
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as! JoinGroupPopupViewController
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

extension ViewController: addGroupPin {
    func createPinFromGroup(group: Group){
                print("created a group")
                var subtitle = "Meeting Time: \(dateToString(datetime: group.datetime))"
                subtitle += "\nDuration ~ \(getHoursMinutes(time: group.duration))"
                if(group.hasDog){
                    subtitle += "\nHas Dogs"
                }
                if(group.hasKid){
                    subtitle += "\nHas Kids"
                }
        
                let discipline = group.isWalking ? "In Progress" : "Not Started"
        
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(group.latitude)!, Double(group.longitude)!)
                let annotation = LocationPointer(title: group.groupName, subtitle: subtitle, discipline: discipline, coordinate:  coordinate, groupId: group.groupId)
                map.addAnnotation(annotation)
            }
}
