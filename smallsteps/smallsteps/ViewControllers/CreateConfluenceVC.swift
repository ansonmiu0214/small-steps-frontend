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
  var otherPerson: (String, CLLocationCoordinate2D) = ("Bob", CLLocationCoordinate2D(latitude: 51.4943, longitude: -0.1826))
  
  override func viewDidLoad() {
    setUpCreateGroupForm()
    super.viewDidLoad()
  }
  
  func setUpCreateGroupForm() {
    let nextButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(CreateConfluenceVC.createConfluence))
    self.navigationItem.rightBarButtonItem = nextButton
    
//    let locationRow = LocationRow(tag: "location", otherPerson: otherPerson)
    let locationRow = LocationRow("locationRow") {
      $0.title = "Location"
      $0.tag = "location"
      let locManager = CLLocationManager()
      $0.value = CLLocation(latitude: (locManager.location?.coordinate.latitude)!, longitude: (locManager.location?.coordinate.longitude)!)
      }.onChange { [weak self] row in
        self!.tableView!.reloadData()
      }
    
    locationRow.otherPerson = otherPerson
    
    form +++ Section("Confluence Details")
      <<< locationRow
  }
  
  @objc func createConfluence() {
    performSegue(withIdentifier: "unwindToVC", sender: self)
//    performSegue(withIdentifier: "confluenceToMain", sender: self)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destVC = segue.destination as? ViewController {
      destVC.isConfluenceButtonClick = true
      destVC.otherPersonWalkerId = otherConfluenceID
      destVC.confluenceLocation = CLLocationCoordinate2D(latitude: Double("\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.latitude)!)")!, longitude: Double("\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.longitude)!)")!)
      
    }
  }
  
  
}

