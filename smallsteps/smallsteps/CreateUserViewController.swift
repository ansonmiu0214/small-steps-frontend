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

class CreateUserViewController: UIViewController {
   
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(CreateUserViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateUserViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    
    @IBAction func continueToMain(_ sender: Any) {
        //Set the data fields
        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
        let defaultImg: String = "default.png"
        
        //Create the walker parameters
        
        let walkerParams: Parameters = [
            "device_id": deviceID,
            "name": self.name.text ?? "John Doe",
            "picture": defaultImg,
            "phone_number": self.phoneNumber.text ?? "00000000000"
        ]

        
        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/walker", method: .post, parameters: walkerParams, encoding: JSONEncoding.default)
            .response {response in
                print(response.response?.statusCode ?? "no response!")
                if let optStatusCode = response.response?.statusCode{
                    switch optStatusCode {
                        case 200...300:
                            self.performSegue(withIdentifier: "continueToNext", sender: nil)
                        default:
                            print("error")
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            self.phoneNumber.text = ""
                            self.phoneNumber.placeholder = "Please Enter a Valid Number!"
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
