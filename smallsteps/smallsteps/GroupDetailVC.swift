//
//  GroupDetailVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 11/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

class GroupDetailVC: UIViewController {
    @IBOutlet weak var groupName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupName.text = yourGroupNames[myIndex]
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
