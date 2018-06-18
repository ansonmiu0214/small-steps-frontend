//
//  HttpUtils.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import MapKit

// Constants
let UUID: String = UIDevice.current.identifierForVendor!.uuidString
let SERVER_IP: String = "http://146.169.45.120:8080/smallsteps"
let TIMEOUT_IN_SECS = 60.0
let DEFAULT_LAT = 51.4989
let DEFAULT_LNG = -0.1790
let DEFAULT_COORD = CLLocationCoordinate2D(latitude: DEFAULT_LAT, longitude: DEFAULT_LNG)
let DEFAULT_TEL = "07756790065"
let DEFAULT_GROUP_ID = "-1"
let CONFLUENCE_THRESHOLD_IN_METRES = 3.0

// HTTP status codes
let HTTP_OK = 200
let HTTP_BAD_REQUEST = 400
let HTTP_NOT_FOUND = 404
let HTTP_SERVICE_UNAVAILABLE = 503

// Protocols
protocol HandleGroupSelection {
  func selectAnnotation(group: Group)
}

protocol ConfluenceDelegate {
  func requestAdminPermission(adminId: String)
  func respondToRequest(otherPersonId: String, didAccept: Bool)
  func sendLocationToUser(otherUserId: String)
  func renderConfluencePoint()
  func renderOtherPersonLocation(newLocation: CLLocationCoordinate2D)
  func confluenceRequestAlert(otherPersonId: String, otherPersonLoc: CLLocation)
  func confluenceDeclinedAlert()
  func resetConfluenceVariables()
}

protocol PinViewDelegate {
  func initialisePinDetailView(group: Group)
  func deinitialisePinDetailView()
}

/**
 * Date/Time conversions
 */
func dateStringToDate(_ dateString: String) -> Date {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
  return formatter.date(from: dateString)!
}

func dateToString(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
  return formatter.string(from: date)
}

func durationStringToDate(_ durationString: String) -> Date {
  let formatter = DateFormatter()
  formatter.dateFormat = "hh:mm:ss"
  return formatter.date(from: durationString)!
}

func durationToString(_ duration: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "hh:mm:ss"
  return formatter.string(from: duration)
}

func prettyDurationToString(time: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "K:mm"
  let durationString = formatter.string(from: time).split(separator: ":")
  
  let (hr, min) = (durationString[0], durationString[1])
  
  let (hr_int, min_int) = (Int(hr)!, Int(min)!)
  
  var hr_str: String {
    switch hr_int {
    case 0:   return ""
    case 1:   return "\(hr) hour "
    default:  return "\(hr) hours "
    }
  }
  
  var min_str: String {
    switch min_int {
    case 0:   return ""
    case 1:   return "\(min) minute"
    default:  return "\(min) minutes"
    }
  }
  
  return hr_str + min_str
}

func prettyDateToString(date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMMM d yyyy, h:mm a"
  return formatter.string(from: date)
}

func getHoursMinutes(time: Date) -> String {
  let dateFormatter: DateFormatter = DateFormatter()
  dateFormatter.dateFormat = "H"
  let newHour: String = dateFormatter.string(from: time)
  dateFormatter.dateFormat = "m"
  let newMinute: String = dateFormatter.string(from: time)
  
  if newHour == "0" { return "\(newMinute) minutes" }
  var hour = "\(newHour) hour"
  if newHour != "1" { hour.append("s") }
  
  if newMinute == "0" { return hour }
  return "\(hour) and \(newMinute) minutes"
}

/**
 * Async request handlers
 */
func getDeviceOwner(deviceID:String, completion: @escaping (String) -> Void) {
  DispatchQueue(label: "Get Device Owner", qos: .background).async {
    let params: Parameters = [
      "device_id": deviceID,
      ]
    
    Alamofire.request("\(SERVER_IP)/walker/name", method: .get, parameters: params)
      .responseJSON { response in
        if let data = response.data, let name = String(data: data, encoding: .utf8) {
          completion(name.trimmingCharacters(in: .whitespaces))
        }
    }
  }
}

func getGroups(center: CLLocationCoordinate2D, completion: @escaping ([Group]) -> Void) {
  DispatchQueue(label: "Get Groups", qos: .background).async {
    let params: Parameters = [
      "latitude": String(center.latitude),
      "longitude": String(center.longitude)
    ]
    
    Alamofire.request("\(SERVER_IP)/groups", method: .get, parameters: params)
      .responseJSON { response in
        let allGroups = parseGroupsFromJSON(res: response)
        completion(allGroups)
    }
  }
}

func addWalkerToGroup(groupId: String, completion: @escaping (Bool) -> Void)  {
  DispatchQueue(label: "JoinRequest", qos: .background).async {
    let params: Parameters = [
      "group_id": groupId,
      "walker_id": UUID
    ]
    
    Alamofire.request("\(SERVER_IP)/groups", method: .put, parameters: params)
      .responseJSON { response in
        completion(response.response?.statusCode == HTTP_OK)
    }
  }
}

func getAdminFromGroup(groupId: String, completion: @escaping (String) -> ()) {
  DispatchQueue(label: "Get AdminId", qos: .background).async {
    let params: Parameters = ["group_id": groupId]
    
    Alamofire.request("\(SERVER_IP)/groups/admin", method: .get, parameters: params)
      .response { response in
        if let data = response.data, let id = String(data: data, encoding: .utf8) {
          completion(id.trimmingCharacters(in: .whitespaces))
        }
    }
  }
}

func queryBuilder(endpoint: String, params: [(String, String)] = []) -> String {
  let queryParams = params.map { key, value in (key + "=" + value) }.joined(separator: "&")
  return "\(SERVER_IP)/\(endpoint)" + (params.isEmpty ? "" : "?\(queryParams)")
}

func getGroupsByUUID(completion: @escaping ([Group]) -> Void) {
  DispatchQueue(label: "GetUserGroups", qos: .background).async {
    let query = queryBuilder(endpoint: "groups", params: [("device_id", UUID)])
    Alamofire.request(query, method: .get).responseJSON { response in
      let userGroups = parseGroupsFromJSON(res: response)
      
      globalUserGroups = [:]
      userGroups.forEach { globalUserGroups[Int($0.groupId)!] = $0 }
      completion(userGroups)
    }
  }
}


/**
 * UI element builders
 */
func buildLoadingOverlay(title: String? = nil, message: String) -> UIAlertController {
  let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
  alert.view.tintColor = UIColor.black
  
  let indicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
  indicator.hidesWhenStopped = true
  indicator.activityIndicatorViewStyle = .gray
  indicator.startAnimating()
  
  alert.view.addSubview(indicator)
  return alert
}


