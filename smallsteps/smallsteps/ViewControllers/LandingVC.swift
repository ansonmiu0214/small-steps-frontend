//
//  LandingVC.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Alamofire

class LandingVC: UIViewController, CLLocationManagerDelegate {
  
  let locationMgr = CLLocationManager()
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  func recognisedDevice(completion: @escaping (String) -> Void) {
    let requestURL = queryBuilder(endpoint: "walker", params: [("device_id", UUID)])

    Alamofire.request(requestURL, method: .get).responseJSON { [unowned self] response in
      self.spinner.stopAnimating()
      switch response.response?.statusCode {
      case HTTP_OK:
        completion("isRegistered")
      case HTTP_NOT_FOUND:
        completion("notRegistered")
      default:
        let alert = UIAlertController(title: "Service Unavailable", message: "Please try again later.", preferredStyle: UIAlertControllerStyle.alert)
        
        self.present(alert, animated: true, completion: nil)
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    checkLocationPermission()
  }
  
  func askForLocationPermission() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "To take advantage of all features in Small Steps, please enable Location Services in Settings.", preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    // Spinner
    spinner.hidesWhenStopped = true
    spinner.startAnimating()
    
    checkLocationPermission()
    super.viewDidLoad()
  }
  
  func checkLocationPermission() {
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      locationMgr.requestWhenInUseAuthorization()
    case .denied, .restricted:
      askForLocationPermission()
      return
    default:
      break
    }
    
    DispatchQueue(label: "Check Walker Registration", qos: .background).async {
      self.recognisedDevice { [unowned self] isRegistered in
        self.spinner.stopAnimating()
        print(isRegistered)
        self.performSegue(withIdentifier: isRegistered, sender: nil)
      }
    }
  }
  
}
