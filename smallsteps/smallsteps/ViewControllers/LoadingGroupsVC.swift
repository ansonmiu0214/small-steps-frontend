//
//  LoadingGroupsViewController.swift
//  smallsteps
//
//  Created by Cheryl Chen on 2018/6/11.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
class LoadingGroupsVC: UIViewController {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    func loadYourGroups(completion: @escaping () -> Void){
        print("LOAAADING GROUPS!!!!!!!!!!!!")
        let yourGroupParams: Parameters = [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            ]
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .get, parameters: yourGroupParams, encoding: URLEncoding.default)
            .responseJSON { (responseData) -> Void in
                if((responseData.result.value) != nil) {
                    if let swiftyJsonVar = try? JSON(responseData.result.value!) {
                        for (_, item) in swiftyJsonVar{
                            yourGroups.append(ViewController.createGroupFromJSON(item: item))
                            yourGroupNames.append(item["name"].string!)
                            yourGroupNames = Array(Set(yourGroupNames))
                            print("THE GROUP NAME IS: \(item["name"].string)")
                        }
                    }
                    completion()
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        DispatchQueue(label: "Check User Groups", qos: .background).async {
            self.loadYourGroups() {
                self.performSegue(withIdentifier: "showUserGroups", sender: nil)
            }
        }
        
    }
    
}
