//
//  HttpUtils.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation
import UIKit

let HTTP_OK = 200
let HTTP_BAD_REQUEST = 400
let HTTP_NOT_FOUND = 404
let HTTP_SERVICE_UNAVAILABLE = 503

func getHoursMinutes(time: Date) -> String {
  let dateFormatter: DateFormatter = DateFormatter()
  dateFormatter.dateFormat = "H"
  let newHour: String = dateFormatter.string(for: time)!
  dateFormatter.dateFormat = "m"
  let newMinute: String = dateFormatter.string(from: time)
  if newHour == "0"{
    return "\(newMinute) minutes"
  }
  var hour: String
  if(newHour == "1"){
    hour = "\(newHour) hour"
  }
  hour = "\(newHour) hours"
  if(newMinute == "0"){
    return hour
  }
  
  return "\(hour) and \(newMinute) minutes"
}

func queryBuilder(endpoint: String, params: [(String, String)] = []) -> String {
  let queryParams = params.map { key, value in (key + "=" + value) }
                          .joined(separator: "&")
  
  return "\(SERVER_IP)/\(endpoint)" + (params.isEmpty ? "" : "?\(queryParams)")
}

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
