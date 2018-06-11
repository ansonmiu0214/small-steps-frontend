//
//  CreateUserViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation

class CreateUserVC: UIViewController {
  
  @IBOutlet weak var name: UITextField!
  @IBOutlet weak var phoneNumber: UITextField!
  
  override func viewDidLoad() {
    NotificationCenter.default.addObserver(self, selector: #selector(CreateUserVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(CreateUserVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    name.autocapitalizationType = .words
    phoneNumber.keyboardType = .phonePad
    super.viewDidLoad()
  }
  
  @objc func keyboardWillShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      self.view.frame.origin.y = -keyboardSize.height
    }
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      if self.view.frame.origin.y != 0 {
        self.view.frame.origin.y += keyboardSize.height
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
  
  func badFormHandler() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    self.phoneNumber.text = ""
    self.phoneNumber.placeholder = "Please enter a valid phone number."
    
    let alert = UIAlertController(title: "Invalid Details", message: "Make sure you are entering a valid phone number.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
  
  func serviceUnavailableHandler() {
    let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
  
  @IBAction func continueToMain(_ sender: Any) {
    // Render loading overlay
    let alert = buildLoadingOverlay(message: "Signing you up...")
    present(alert, animated: true, completion: nil)
    
    // Create the walker parameters
    let walkerParams: Parameters = [
      "device_id": UUID,
      "name": self.name.text!,
      "picture": "default.png",
      "phone_number": self.phoneNumber.text!
    ]
    
    // POST the JSON to the server
    DispatchQueue(label: "Create Walker", qos: .background).async {
      Alamofire.request("\(SERVER_IP)/walker", method: .post, parameters: walkerParams, encoding: JSONEncoding.default)
        .responseJSON { [unowned self] response in
          // Stop spinning screen
          alert.dismiss(animated: false) { [unowned self] in
            switch (response.response!.statusCode) {
            case HTTP_OK:
              self.performSegue(withIdentifier: "continueToNext", sender: nil)
            case HTTP_BAD_REQUEST:
              self.badFormHandler()
            default:
              self.serviceUnavailableHandler()
            }
          }
      }
    }
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}
