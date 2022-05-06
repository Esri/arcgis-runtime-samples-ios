//
//  DisplayRouteLayerViewController.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Vivian Quach on 4/29/22.
//  Copyright © 2022 Esri. All rights reserved.
//

import UIKit
import ArcGIS

class DisplayRouteLayerViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with basemap.
            mapView.map = makeMap()
        }
    }
    
    var directions = [String]()
    
    func makeMap() -> AGSMap {
        // Set the basemap.
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        // Set the portal.
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        // Create the portal item with the item ID for route data in Portland, OR.
        let item = AGSPortalItem(portal: portal, itemID: "0e3c8e86b4544274b45ecb61c9f41336")
        // Create a collection of features using the item.
        let featureCollection = AGSFeatureCollection(item: item)
        // Create a feature collection layer uisng the feature collection.
        let featureCollectionLayer = AGSFeatureCollectionLayer(featureCollection: featureCollection)
        featureCollection.load { error in
            let tables = featureCollection.tables as! [AGSFeatureCollectionTable]
            let directionsTable = tables.first(where: { $0.tableName == "DirectionPoints"})
            let features = directionsTable?.featureEnumerator().allObjects
            self.directions = features?.compactMap { $0.attributes["DisplayText"] } as! [String]
            
        }
        // Set the feature collection layere to the map's operational layers.
        map.operationalLayers.setArray([featureCollectionLayer])
        // Set the viewpoint.
        let viewpoint = AGSViewpoint(latitude: 45.2281, longitude: -122.8309, scale: 57e4)
        map.initialViewpoint = viewpoint
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayRouteLayerViewController"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? DisplayDirectionsViewController {
            controller.directions = directions
        }
    }
}
