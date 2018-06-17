import Foundation
import CoreLocation
import SwiftyJSON
import Alamofire

func parseGroupsFromJSON(res: DataResponse<Any>) -> [Group] {
  var parsedGroups: [Group] = []
  if let jsonVal = res.result.value {
    let jsonVar = JSON(jsonVal)
    for (_, item) in jsonVar {
      parsedGroups.append(createGroupFromJSON(item: item))
    }
  }
  return parsedGroups
}

func createGroupFromJSON(item: JSON) -> Group{
  //Convert JSON to string to datetime
  let dateFormatterDT: DateFormatter = DateFormatter()
  dateFormatterDT.dateFormat = "yyyy-MM-dd hh:mm:ss"
  let newDate: Date = dateFormatterDT.date(from: item["time"].string!)!
  
  //Convert JSON to string to duration
  let dateFormatterDur: DateFormatter = DateFormatter()
  dateFormatterDur.dateFormat = "hh:mm:ss"
  let newDuration: Date = dateFormatterDur.date(from: item["duration"].string!)!
  
  return Group( groupName: item["name"].string!,
                datetime: dateStringToDate(item["time"].string!),
                repeats: "yes",
                duration: durationStringToDate(item["duration"].string!),
                latitude: item["location_latitude"].string!,
                longitude: item["location_longitude"].string!,
                hasDog: item["has_dogs"].bool!,
                hasKid: item["has_kids"].bool!,
                adminID: item["admin_id"].string!,
                isWalking: item["is_walking"].bool!,
                description: item["description"].string!,
                groupId: item["id"].string!,
                numberOfPeople: item["number_of_people"].int!
              )
}

class Group: Equatable {
  static func == (lhs: Group, rhs: Group) -> Bool {
    return lhs.groupId == rhs.groupId
  }
  
  var groupName: String
  var datetime: Date
  var repeats: String
  var duration: Date
  var latitude: String
  var longitude: String
  var hasDog: Bool
  var hasKid: Bool
  var adminID: String
  var isWalking: Bool
  var description: String
  var groupId: String
  var numberOfPeople: Int
  
  init(groupName: String, datetime: Date, repeats: String, duration: Date, latitude: String, longitude: String, hasDog: Bool, hasKid: Bool = false, adminID: String, isWalking: Bool = false, description: String = "A Small Steps walking group", groupId: String = "-1", numberOfPeople: Int = 1) {
    self.groupName = groupName
    self.datetime = datetime
    self.repeats = repeats
    self.duration = duration
    self.latitude = latitude
    self.longitude = longitude
    self.hasDog = hasDog
    self.hasKid = hasKid
    self.adminID = adminID
    self.isWalking = isWalking
    self.description = description
    self.groupId = groupId
    self.numberOfPeople = numberOfPeople
  }
  
}
