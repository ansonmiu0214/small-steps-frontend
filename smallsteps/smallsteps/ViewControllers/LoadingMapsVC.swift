//
//  LoadingMapsVC.swift
//  smallsteps
//
//  Created by Cheryl Chen on 2018/6/11.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation

class LoadingMapsVC: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    func loadGroups(completion: @escaping () -> Void){
        var latitude: String
        var longitude: String
        if let location = CLLocationManager().location?.coordinate{
            latitude = String(location.latitude)
            longitude = String(location.longitude)
        } else{
            latitude = "51.4989"
            longitude = "-0.1790"
        }
        
        let localGroupsParams: Parameters = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .get, parameters: localGroupsParams, encoding: URLEncoding.default)
            .responseJSON { (responseData) -> Void in
                if((responseData.result.value) != nil) {
                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                        for (_, item) in swiftyJsonVar{
                            groups.append(createGroupFromJSON(item: item))
                        }
                    }
                }
                completion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        DispatchQueue(label: "UpdateMap", qos: .background).async {
            self.loadGroups() {
                self.performSegue(withIdentifier: "goToMap", sender: nil)
            }
        }
        
    }

}
