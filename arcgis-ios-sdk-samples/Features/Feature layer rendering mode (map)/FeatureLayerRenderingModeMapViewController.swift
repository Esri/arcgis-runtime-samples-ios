// Copyright 2018 Esri.
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

class FeatureLayerRenderingModeMapViewController: UIViewController {
    
    @IBOutlet weak var dynamicMapView: AGSMapView!
    @IBOutlet weak var staticMapView: AGSMapView!
    
    var _zoomed = false
    var zoomedInViewpoint : AGSViewpoint!
    var zoomedOutViewpoint : AGSViewpoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerRenderingModeMapViewController"]
        
        //points for zoomed in and zoomed out
        let zoomedInPoint = AGSPoint(x: -118.37, y: 34.46, spatialReference: AGSSpatialReference.wgs84())
        let zoomedOutPoint = AGSPoint(x: -118.45, y: 34.395, spatialReference: AGSSpatialReference.wgs84())
        zoomedInViewpoint = AGSViewpoint(center: zoomedInPoint, scale: 650000, rotation: 0)
        zoomedOutViewpoint = AGSViewpoint(center: zoomedOutPoint, scale: 50000, rotation: 90)
        
        //assign maps to the map views
        self.dynamicMapView.map = AGSMap()
        self.staticMapView.map = AGSMap()
        
        //create service feature tables using point,polygon, and polyline services
        let pointTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/0")!)
        let polylineTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/8")!)
        let polygonTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        //create feature layers from the feature tables
        let featureLayers: [AGSFeatureLayer] = [
            AGSFeatureLayer(featureTable: polygonTable),
            AGSFeatureLayer(featureTable: polylineTable),
            AGSFeatureLayer(featureTable: pointTable)]
        
        for featureLayer in featureLayers {
            //add the layer to the dynamic view
            featureLayer.renderingMode = AGSFeatureRenderingMode.dynamic
            self.dynamicMapView.map?.operationalLayers.add(featureLayer)
            
            //add the layer to the static view
            let staticFeatureLayer = featureLayer.copy() as! AGSFeatureLayer
            staticFeatureLayer.renderingMode = AGSFeatureRenderingMode.static
            self.staticMapView.map?.operationalLayers.add(staticFeatureLayer)
        }
        
        //set the initial viewpoint
        self.dynamicMapView.setViewpoint(zoomedOutViewpoint)
        self.staticMapView.setViewpoint(zoomedOutViewpoint)
    }

    @IBAction func animateZoom(_ sender: Any) {
        if _zoomed {
            self.dynamicMapView.setViewpoint(zoomedOutViewpoint, duration: 5, completion: nil)
            self.staticMapView.setViewpoint(zoomedOutViewpoint, duration: 5, completion: nil)
        } else {
            self.dynamicMapView.setViewpoint(zoomedInViewpoint, duration: 5, completion: nil)
            self.staticMapView.setViewpoint(zoomedInViewpoint, duration: 5, completion: nil)
        }
        _zoomed = !_zoomed
    }
    
}
