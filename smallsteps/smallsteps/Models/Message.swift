//
//  Message.swift
//  smallsteps
//
//  Created by Anson Miu on 17/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation

struct SenderResponse: Decodable{
  let sender: String
  let senderLat: String
  let senderLong: String
  enum CodingKeys: String, CodingKey {
    case sender
    case senderLat
    case senderLong
  }
}

struct LocationResponse: Decodable{
  let lat: String
  let long: String
  let senderID: String
  enum CodingKeys: String, CodingKey{
    case lat
    case long
    case senderID
  }
}

struct Response: Decodable{
  let response:Bool
  let latitude: String?
  let longitude: String?
  let confluenceLat: String?
  let confluenceLong: String?
  
  enum CodingKeys: String, CodingKey{
    case response
    case latitude
    case longitude
    case confluenceLat
    case confluenceLong
  }
}
