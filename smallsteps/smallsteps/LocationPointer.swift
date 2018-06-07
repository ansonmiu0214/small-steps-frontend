import MapKit

class LocationPointer: NSObject, MKAnnotation {
    var markerTintColor: UIColor  {
        switch discipline {
        case "Not Started":
            return .green
        case "In Progress":
            return .orange
        default:
            return .blue
        }
    }
    
    let title: String?
    let subtitle: String?
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    let groupId: String
    
    init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D, groupId: String = "-1") {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
        self.groupId = groupId
        
        super.init()
    }
    
}
