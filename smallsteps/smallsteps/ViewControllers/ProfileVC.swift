//
//  ProfileVC.swift
//  smallsteps
//
//  Created by Anson Miu on 18/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

class ProfileVC: UIViewController {
  
  @IBOutlet weak var heading: UILabel!
  
  override func viewWillAppear(_ animated: Bool) {
    getDeviceOwner(deviceID: UUID) { name in
      self.heading.text = name
    }
    
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = "Profile"
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
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
