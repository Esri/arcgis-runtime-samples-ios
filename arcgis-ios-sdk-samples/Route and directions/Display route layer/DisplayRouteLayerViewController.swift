//
//  DisplayRouteLayerViewController.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Vivian Quach on 4/29/22.
//  Copyright © 2022 Esri. All rights reserved.
//

import UIKit
import ArcGIS

class DisplayRouteLayer: UIViewController {
    @IBOutlet var mapView: AGSMap! {
        didSet {
            // Assign the map to the map view.
//            mapView.map = makeMap()
        }
    }
    
    func makeMap() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayMapViewController"]
    }
}
