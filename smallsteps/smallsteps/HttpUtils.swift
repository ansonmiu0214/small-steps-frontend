//
//  HttpUtils.swift
//  smallsteps
//
//  Created by Anson Miu on 9/6/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import Foundation

func queryBuilder(endpoint: String, params: [(String, String)] = []) -> String {
  let queryParams = params.map { key, value in (key + "=" + value) }
                          .joined(separator: "&")
  
  return "\(SERVER_IP)/\(endpoint)" + (params.isEmpty ? "" : "?\(queryParams)")
}
