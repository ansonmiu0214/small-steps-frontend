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
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  func recognisedDevice(completion: @escaping (String) -> Void) {
    let requestURL = queryBuilder(endpoint: "walker", params: [("device_id", UUID)])
    
    print(requestURL)
    Alamofire.request(requestURL, method: .get).responseJSON { response in
      self.spinner.stopAnimating()
      switch response.response?.statusCode {
      case 200:
        completion("isRegistered")
      case 404:
        completion("notRegistered")
      default:
        let alert = UIAlertController(title: "Service Unavailable", message: "Please try again later.", preferredStyle: UIAlertControllerStyle.alert)
        
        self.present(alert, animated: true, completion: nil)
      }
    }
  }
  
  override func viewDidLoad() {
    spinner.hidesWhenStopped = true
    spinner.startAnimating()
    
    DispatchQueue(label: "Check Walker Registration", qos: .background).async {
      self.recognisedDevice { isRegistered in
        self.performSegue(withIdentifier: isRegistered, sender: nil)
      }
    }
    
    super.viewDidLoad()
  }
  
}
