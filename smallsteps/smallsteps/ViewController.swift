//
//  ViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import MapKit
import Alamofire


class ViewController: UIViewController {
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var MapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey("AIzaSyATspIpIWzFayJLuLkTOCXaeuhCoEfLfIo")
        
        let camera = GMSCameraPosition.camera(withLatitude: 51.4989562, longitude: -0.1801277, zoom: 100)
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 100, height: 100))
        let MapView = GMSMapView.map(withFrame: rect, camera: camera)
        
        menuButton.bringSubview(toFront: view)
        Alamofire.request("http://146.169.45.120:8080/smallsteps/greeting").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}

