//
//  CreateGroupTVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Eureka
import Alamofire
import CoreLocation

class CreateConfluenceVC: FormViewController {
    
    var otherConfluenceID: String?
    
    override func viewDidLoad() {
        setUpCreateGroupForm()
        super.viewDidLoad()
    }
    
    func setUpCreateGroupForm() {
        let nextButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(CreateConfluenceVC.createConfluence))
        self.navigationItem.rightBarButtonItem = nextButton
        
        form +++ Section("Confluence Details")
            <<< LocationRow("location") {
                $0.title = "Location"
                $0.tag = "location"
                let locManager = CLLocationManager()
                $0.value = CLLocation(latitude: (locManager.location?.coordinate.latitude)!, longitude: (locManager.location?.coordinate.longitude)!)
                }.onChange { [weak self] row in
                    self!.tableView!.reloadData()
        }
    }
    
    @objc func createConfluence() {
        performSegue(withIdentifier: "confluenceToMain", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? ViewController {
            destVC.isConfluenceButtonClick = true
            destVC.otherConfluenceID = otherConfluenceID
            destVC.confluenceLocation = CLLocationCoordinate2D(latitude: Double("\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.latitude)!)")!, longitude: Double("\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.longitude)!)")!)
            
        }
    }

    
}

