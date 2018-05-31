//
//  CreateUserViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
//import Firebase

class CreateUserViewController: UIViewController {
    @IBOutlet var name: UITextField!
    
    @IBOutlet var AddUserButton: UIButton!
    //var ref:DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
           // ref = Database.database().reference()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createNewUser(_ sender: Any) {
        //Post data to firebase
       // ref?.child("Users").childByAutoId().child("Name").setValue(name.text)
        
        //Dismiss the popover
        presentingViewController?.dismiss(animated: true, completion: nil)
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
