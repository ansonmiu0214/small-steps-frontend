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

class CreateGroupVC: FormViewController {

  override func viewDidLoad() {
    setUpCreateGroupForm()
    super.viewDidLoad()
  }
  
  func setUpCreateGroupForm() {
    let nextButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(CreateGroupVC.createGroup))
    nextButton.isEnabled = false
    self.navigationItem.rightBarButtonItem = nextButton
    
    form +++ Section("Group Details")
      <<< TextRow(){ row in
        row.tag = "groupName"
        row.title = "Name"
        row.placeholder = "Enter group name here"
        row.add(rule: RuleRequired(msg: "This field is required"))
        row.validationOptions = .validatesOnDemand
        }.cellUpdate { cell, row in
          self.form.validate()
          if !row.isValid {
            cell.titleLabel?.textColor = .red
            nextButton.isEnabled = false
          } else {
            nextButton.isEnabled = true
          }
      }
      +++ Section("Meeting Date and Time")
      <<< DateTimeRow(){
        $0.tag = "datetime"
        $0.title = "Date and Time"
        $0.value = Date()
      }
      <<< ActionSheetRow<String>() {
        $0.tag = "repeat"
        $0.title = "Repeat"
        $0.selectorTitle = "Pick a Day"
        $0.options = ["Daily"]
        $0.value = "Daily"    // initially selected
      }
      <<< CountDownRow() {
        $0.tag = "duration"
        $0.title = "Estimated Duration"
        $0.value = Calendar.current.date(bySettingHour: 0, minute: 30, second: 0, of: Date())
      }
      +++ Section("Details")
      <<< SwitchRow() { row in
        row.tag = "hasDogs"
        row.title = "Dog Friendly"
      }
      //            <<< SwitchRow() { row in
      //                row.tag = "hasKids"
      //                row.title = "With Kids"
      //            }
      <<< LocationRow("location") {
        $0.title = "Location"
        $0.tag = "location"
        let locManager = CLLocationManager()
        $0.value = CLLocation(latitude: (locManager.location?.coordinate.latitude)!, longitude: (locManager.location?.coordinate.longitude)!)
        }.onChange { [weak self] row in
          self!.tableView!.reloadData()
    }
  }
  
  @objc func setLocation() {
    performSegue(withIdentifier: "setLocation", sender: self)
  }
  
  @objc func createGroup() {
    // Build group
    let valuesDict = form.values()
    let newGroup: Group = Group(groupName: valuesDict["groupName"] as! String,
                                datetime: valuesDict["datetime"] as! Date,
                                repeats: valuesDict["repeat"] as! String ,
                                duration: valuesDict["duration"] as! Date,
                                latitude: "\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.latitude)!)",
      longitude: "\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.longitude)!)",
        hasDog: ((form.rowBy(tag: "hasDogs") as? SwitchRow)?.cell.switchControl.isOn)!,
      adminID: UUID,
      description: valuesDict["description"] as! String)
    
    // Show progress overlay
    let alert = buildLoadingOverlay(message: "Setting up \"\(newGroup.groupName)\"")
    present(alert, animated: true, completion: nil)
    
    //Create the walker parameters
    let groupParams: Parameters = [
      "name": newGroup.groupName,
      "time": removeTimezone(datetime: newGroup.datetime),
      "description": "Some description",
      "admin_id": newGroup.adminID,
      "location_latitude": newGroup.latitude,
      "location_longitude": newGroup.longitude,
      "duration": getHoursMinutesSeconds(time: newGroup.duration),
      "has_dogs": false,
      "has_kids": false
    ]
    
    // Submit POST request
    DispatchQueue(label: "Create Group", qos: .background).async {
      Alamofire.request("\(SERVER_IP)/groups", method: .post, parameters: groupParams, encoding: JSONEncoding.default)
        .responseJSON { [unowned self] response in
          alert.dismiss(animated: false) {
            if let statusCode = response.response?.statusCode {
              switch statusCode {
              case HTTP_OK:
                // TODO reload groups
                self.performSegue(withIdentifier: "returnHome", sender: nil)
              case HTTP_BAD_REQUEST:
                self.badFormHandler()
              default:
                self.serviceUnavailableHandler()
              }
            } else {
              self.serviceUnavailableHandler()
            }
          }
      }
    }
  }
  
  // TODO enforce protocol for these handlers
  private func badFormHandler() {
    let alert = UIAlertController(title: "Invalid Details", message: "Please verify the details of the group you are trying to create.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
  
  // TODO enforce protocol for these handlers
  private func serviceUnavailableHandler() {
    let alert = UIAlertController(title: "Service Unavailable", message: "Please check your network connections and try again later.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
  
  func removeTimezone(datetime: Date) -> String {
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
    let newDate: String = dateFormatter.string(for: datetime)!
    //print("THE NEW DATE IS: \(newDate)")
    return newDate
  }

  func getHoursMinutesSeconds(time: Date) -> String {
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "hh:mm:ss"
    let newTime: String = dateFormatter.string(for: time)!
    print("THE NEW TIME IS: \(newTime)")
    
    return newTime
  }
  
}

