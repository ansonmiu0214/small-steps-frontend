import MapKit

class MeetingPointMarker: NSObject, MKAnnotation {
  
  let identifier: String?
  let title: String?
  let coordinate: CLLocationCoordinate2D
  let group: Group?
  
  init(identifier: String, title: String, coordinate: CLLocationCoordinate2D, group: Group? = nil) {
    self.identifier = identifier
    self.title = title
    self.coordinate = coordinate
    self.group = group
    
    super.init()
  }
  
}
