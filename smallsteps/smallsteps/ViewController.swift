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
    @IBOutlet weak var searchBar: UISearchBar!
    
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
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    
        
//        Alamofire.request("http://146.169.45.120:8080/smallsteps/startingWalk").responseJSON { (responseData) -> Void in
//            if((responseData.result.value) != nil) {
//                let swiftyJsonVar = JSON(responseData.result.value!)
//                print(swiftyJsonVar)
//                let resData = swiftyJsonVar["content"].stringValue
//                self.searchBar.text = resData
//                print(resData)
//
//            }
//        }
    }
    
    @IBAction func findFriends(_ sender: Any) {
        let name = searchBar.text
        Alamofire.request("http://146.169.45.120:8080/smallsteps/startingWalk?name=" + name!).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print(swiftyJsonVar)
                let resData = swiftyJsonVar["numberOfWalkers"].stringValue
                self.userId = swiftyJsonVar["id"].int!
                self.searchBar.text = "Currently there are: " + resData + " walkers"
                print(resData)

            }
        }
    }
    
    @IBAction func stopWalking(_ sender: Any) {
        let name = searchBar.text
        Alamofire.request("http://146.169.45.120:8080/smallsteps/stoppingWalk?id=\(userId)").responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print(swiftyJsonVar)
                let resData = swiftyJsonVar["numberOfWalkers"].stringValue
                self.searchBar.text = "Currently there are: " + resData + "Walkers"
                print(resData)
                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}

