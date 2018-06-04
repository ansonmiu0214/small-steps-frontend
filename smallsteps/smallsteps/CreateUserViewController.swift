//
//  CreateGroupViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 04/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit


class CreateUserViewController: UIViewController {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!

    
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

        //Create the walker parameters
 
        let walkerParams: Parameters = [
            "device_id": deviceID,
            "name": name,
            "picture": defaultImg,
            "phone_number": phoneNumber
            ]

        
        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/walker", method: .post, parameters: walkerParams)
        
        
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
