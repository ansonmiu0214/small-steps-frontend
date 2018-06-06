import MapKit

class Artwork: NSObject, MKAnnotation {
    var markerTintColor: UIColor  {
        switch discipline {
        case "Not Started":
            return .green
        case "In Progress":
            return .orange
        case "Just Finished":
            return .red
        default:
            return .blue
        }
    }
    
    let title: String?
    let subtitle: String?
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
//    var subtitle: String? {
//        return subtitle
//    }
}
