//
//  ConfluenceVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 14/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import LocationPickerController

class ConfluenceVC: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewController = LocationPickerController(success: {
            [weak self] (coordinate: CLLocationCoordinate2D) -> Void in
            self?.locationLabel.text = "".appendingFormat("%.4f, %.4f",
                                                          coordinate.latitude, coordinate.longitude)
        })
        let navigationController = UINavigationController(rootViewController: viewController)
    
        self.present(navigationController, animated: true, completion: nil)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
