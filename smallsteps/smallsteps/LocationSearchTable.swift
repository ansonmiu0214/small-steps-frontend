import UIKit
import MapKit

class LocationSearchTable : UITableViewController {
  
  var groups: [Group] = []
  var matchingGroups: [Group] = []
  var handleMapSearchDelegate: HandleGroupSelection? = nil
  
  func filterContentForSearchText(_ searchText: String) {
    matchingGroups = groups.filter { (group: Group) -> Bool in
      return group.groupName.lowercased().contains(searchText.lowercased())
    }
  }
  
}
extension LocationSearchTable : UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
    self.tableView.reloadData()
  }
  
  //just formatting the address for extra prettiness
  func parseAddress(selectedItem:MKPlacemark) -> String {
    //Formatting the Address Line
    // put space between address number and address location
    let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
    // put comma between street name and city name
    let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
    // put space between subAdministrativeArea and administrativeArea
    let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
    
    let addressLine = String(
      format:"%@%@%@%@%@%@%@",
      // street number
      selectedItem.subThoroughfare ?? "",
      firstSpace,
      // street name
      selectedItem.thoroughfare ?? "",
      comma,
      // city
      selectedItem.locality ?? "",
      secondSpace,
      // state
      selectedItem.administrativeArea ?? ""
    )
    return addressLine
  }
}

extension LocationSearchTable {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return matchingGroups.count
  }

  // TODO - make a better subtitle?
  override func tableView(_ tableView: UITableView, cellForRowAt at: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
    let selectedItem = matchingGroups[at.row]
    cell.textLabel?.text = selectedItem.groupName
    
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMMM yyyy HH:mm"
    cell.detailTextLabel?.text = formatter.string(from: selectedItem.datetime)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
    let group = matchingGroups[indexPath.row]
    dismiss(animated: true) { [unowned self] in
      self.handleMapSearchDelegate?.selectAnnotation(group: group)
    }
  }
}

