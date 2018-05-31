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

class ViewController: UIViewController {
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var MapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Alamofire.request("http://146.169.45.120:8080/smallsteps/greeting").responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print(swiftyJsonVar)
                let resData = swiftyJsonVar["content"].stringValue
                self.searchBar.text = resData

            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}

