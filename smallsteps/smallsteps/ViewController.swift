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
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet var map: MKMapView!
    @IBOutlet var menuButton: UIButton!
    
    var resultSearchController:UISearchController? = nil
    
    var userId: Int = 0
    
    let manager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        map.setRegion(region, animated: true)
        
        self.map.showsUserLocation = true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MapKit Setup
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        //Location Search Table Setup
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
       
        //Search Bar Setup
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

