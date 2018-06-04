//
//  CreateUserViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Alamofire

class CreateUserViewController: UIViewController {
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    

    @IBAction func continueToMain(_ sender: Any) {
        //Set the data fields
        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
        let name: String = firstName.text! + " " + lastName.text!
        let defaultImg: String = "default.png"
        let phoneNumber: String  = "123456"
        
        print("deviceID is \(deviceID), name = \(name)")
        
        //Create the walker parameters
        
        let walkerParams: Parameters = [
            "device_id": deviceID,
            "name": name,
            "picture": defaultImg,
            "phone_number": phoneNumber
        ]

        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/walker", method: .post, parameters: walkerParams).response {response in
            if let optStatusCode = response.response?.statusCode{
                print(optStatusCode)
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
