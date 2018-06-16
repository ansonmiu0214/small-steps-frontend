import Foundation
import CoreLocation

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
