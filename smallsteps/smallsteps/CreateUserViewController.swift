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
   
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    
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
        let defaultImg: String = "default.png"
        
        //Create the walker parameters
        
        let walkerParams: Parameters = [
            "device_id": deviceID,
            "name": self.name.text ?? "John Doe",
            "picture": defaultImg,
            "phone_number": self.phoneNumber.text ?? "00000000000"
        ]

        
        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/walker", method: .post, parameters: walkerParams, encoding: JSONEncoding.default).response {response in
            print(response)
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
