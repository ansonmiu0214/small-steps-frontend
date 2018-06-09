//
//  LandingVC.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class LandingVC: UIViewController {
  
  func recognisedDevice(completion: @escaping (String) -> Void) {
    let requestURL = queryBuilder(endpoint: "walker", params: [("device_id", UUID)])

    Alamofire.request(requestURL, method: .get).validate(statusCode: 200..<300).responseJSON { response in
      completion(response.result.isSuccess ? "isRegistered" : "notRegistered")
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    DispatchQueue(label: "Check Walker Registration", qos: .background).async {
      self.recognisedDevice { isRegistered in
        self.performSegue(withIdentifier: isRegistered, sender: nil)
      }
    }
  }
  
}
