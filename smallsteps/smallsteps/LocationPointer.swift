import MapKit

class LocationPointer: NSObject, MKAnnotation {
  
    var markerTintColor: UIColor  {
        switch discipline {
        case "Not Started":
            return .orange
        case "In Progress":
            return .green
        default:
            return .black
        }
    }
    
    let title: String?
    let subtitle: String?
    let discipline: String
    var coordinate: CLLocationCoordinate2D
    let groupId: String
    let group: Group?
    
    init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D, groupId: String = "-1", group: Group? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
        self.groupId = groupId
        self.group = group
        
        super.init()
    }
    
    func changeLocationTo(_ newLocation: CLLocationCoordinate2D) {
        self.coordinate = newLocation
    }
    
}
