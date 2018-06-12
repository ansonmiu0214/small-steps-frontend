//
//  MeetingLocationTableViewCell.swift
//  smallsteps
//
//  Created by Jin Sun Park on 11/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import MapKit

class MeetingLocationTableViewCell: UITableViewCell, MKMapViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet var meetingMap: MKMapView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let manager = CLLocationManager()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        meetingMap!.showsPointsOfInterest = true
        if let meetingMap = self.meetingMap
        {
            meetingMap.delegate = self
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        getGroupsByUUID() { userGroups in
            let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(userGroups[currGroup].latitude)!, Double(userGroups[currGroup].longitude)!)
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.001, 0.001)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            self.meetingMap.setRegion(region, animated: true)
            self.meetingMap.showsUserLocation = true
            self.meetingMap.delegate = self
        }
    }
    
    func showLocation(location:CLLocation) {
        let orgLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = orgLocation
        meetingMap!.addAnnotation(dropPin)
        self.meetingMap?.setRegion(MKCoordinateRegionMakeWithDistance(orgLocation, 500, 500), animated: true)
    }

}
