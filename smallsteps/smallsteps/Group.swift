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
  var placemark: CLPlacemark?
  var hasDog: Bool
  var hasKid: Bool
  var adminID: String
  var isWalking: Bool
  var description: String
  var groupId: String
  
    init(groupName: String, datetime: Date, repeats: String, duration: Date, latitude: String, longitude: String, hasDog: Bool, hasKid: Bool = false, adminID: String, isWalking: Bool = false, description: String = "A Small Steps walking group", groupId: String = "-1") {
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
    
    let location = CLLocation(latitude: Double(self.latitude)!, longitude: Double(self.longitude)!)
    
//    DispatchQueue(label: "Geocoding", qos: .background).async { [unowned self] in
//      CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
//        self.placemark = error == nil ? placemarks![0] : nil
//        print(">> Placemark for \(self.groupName) is \(String(describing: self.placemark?.name!))")
//      }
//    }
    
    
  }
  
  
}
