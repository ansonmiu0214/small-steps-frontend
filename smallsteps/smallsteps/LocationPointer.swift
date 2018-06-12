import MapKit

class LocationPointer: NSObject, MKAnnotation {
  
  var markerTintColor: UIColor  {
    switch discipline {
    case "Not Started":
      return .red
    case "In Progress":
      return .green
    default:
      return .blue
    }
  }
  
  // "Overrides"
  var title: String?
  var subtitle: String?
  let coordinate: CLLocationCoordinate2D
  
  let discipline: String
  let group: Group?
  
  init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D, group: Group? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.discipline = discipline
    self.coordinate = coordinate
    self.group = group
    
    super.init()
  }
  
}
