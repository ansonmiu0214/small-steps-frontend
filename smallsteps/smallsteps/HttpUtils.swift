//
//  HttpUtils.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation

let HTTP_OK = 200
let HTTP_BAD_REQUEST = 400
let HTTP_NOT_FOUND = 404
let HTTP_SERVICE_UNAVAILABLE = 503

func queryBuilder(endpoint: String, params: [(String, String)] = []) -> String {
  let queryParams = params.map { key, value in (key + "=" + value) }
                          .joined(separator: "&")
  
  return "\(SERVER_IP)/\(endpoint)" + (params.isEmpty ? "" : "?\(queryParams)")
}
