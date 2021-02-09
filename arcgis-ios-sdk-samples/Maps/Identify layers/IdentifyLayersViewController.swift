// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class IdentifyLayersViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["IdentifyLayersViewController"]
        
        // Create an instance of a map
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        // Map image layer.
        let mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!)
        
        // hide Continent and World layers
        mapImageLayer.load { [weak mapImageLayer] (error: Error?) in
            if error == nil {
                mapImageLayer?.subLayerContents[1].isVisible = false
                mapImageLayer?.subLayerContents[2].isVisible = false
            }
        }
        map.operationalLayers.add(mapImageLayer)
        
        // Feature table.
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
    
        // Feature layer.
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        // Add feature layer add to the operational layers.
        map.operationalLayers.add(featureLayer)
        
        // Assign map to the map view.
        mapView.map = map
        
        // Set viewpoint to a specific region.
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -10977012.785807, y: 4514257.550369, spatialReference: .webMercator()), scale: 68015210))
        
        // Add self as the touch delegate for the map view.
        mapView.touchDelegate = self
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Get the geoElements for all layers present at the tapped point.
        self.identifyLayers(screenPoint)
    }
    
    // MARK: - Identify layers
    
    private func identifyLayers(_ screen: CGPoint) {
        // Show progress hud.
        SVProgressHUD.show(withStatus: "Identifying")
        
        self.mapView.identifyLayers(atScreenPoint: screen, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { (results: [AGSIdentifyLayerResult]?, error: Error?) in
            // Dismiss progress hud.
            SVProgressHUD.dismiss()
            
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.handleIdentifyResults(results!)
            }
        }
    }
    
    // MARK: - Helper methods
    
    private func handleIdentifyResults(_ results: [AGSIdentifyLayerResult]) {
        var messageString = ""
        var totalCount = 0
        for identifyLayerResult in results {
            let count = self.geoElementsCountFromResult(identifyLayerResult)
            let layerName = identifyLayerResult.layerContent.name
            messageString.append("\(layerName) :: \(count)")
            
            // Add new line character if not the final element in array.
            if identifyLayerResult != results.last! {
                messageString.append(" \n ")
            }
            
            // Update total count.
            totalCount += count
        }
        
        if totalCount > 0 {
            // If any elements were found, show the results.
            presentAlert(title: "Number of elements found", message: messageString)
        } else {
            // Notify user that no elements were found.
            presentAlert(message: "No element found")
        }
    }
    
    private func geoElementsCountFromResult(_ result: AGSIdentifyLayerResult) -> Int {
        // Create temp array.
        var tempResults = [result]
        
        // Using Depth First Search approach to handle recursion.
        var count = 0
        var index = 0
        
        while index < tempResults.count {
            // Get the result object from the array.
            let identifyResult = tempResults[index]
            
            // Update count with geoElements from the result.
            count += identifyResult.geoElements.count
            
            // Check if the result has any sublayer results.
            // If yes then add those result objects in the tempResults
            // array after the current result.
            if !identifyResult.sublayerResults.isEmpty {
                tempResults.insert(contentsOf: identifyResult.sublayerResults, at: index + 1)
            }
            
            // Update the count and repeat.
            index += 1
        }
        
        return count
    }
}
