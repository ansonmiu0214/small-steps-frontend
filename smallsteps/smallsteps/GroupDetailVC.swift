//
//  GroupDetailVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 11/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

class GroupDetailVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupDetailCell", for: indexPath) as! GroupDetailTableViewCell
        cell.groupNameLabel.text = yourGroupNames[myIndex]
        return cell
    }
}
