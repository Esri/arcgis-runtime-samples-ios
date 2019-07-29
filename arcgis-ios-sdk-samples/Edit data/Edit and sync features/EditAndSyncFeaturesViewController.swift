//
// Copyright © 2019 Esri.
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
//

import UIKit
import ArcGIS

class EditAndSyncFeaturesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with a basemap.
            let tileCache = AGSTileCache(name: "SanFrancisco")
            let tiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
            let map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
            
            // Assign the map to the map view.
            mapView.map = map
            mapView.setViewpoint(AGSViewpoint(targetExtent: tileCache.fullExtent!))

            // Display graphics overlay of the download area.
//            displayGraphics()
        }
    }
    
    private var graphicsOverlay: AGSGraphicsOverlay!
    
//    func displayGraphics() {
//        graphicsOverlay = AGSGraphicsOverlay()
//        graphicsOverlay.renderer = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid, color: .red, width: 2))
//        self.mapView.graphicsOverlays.add(graphicsOverlay)
//    }
    @IBOutlet var extentView: UIView! {
        didSet {
            //setup extent view
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 3
        }
    }
    @IBOutlet private var generateButton: UIButton!
    @IBOutlet private var syncButton: UIButton!
    @IBOutlet private var progressBar: UIProgressView!
    
    private var downloadAreaGraphic: AGSGraphic! {
        didSet {
    
        }
    }
    
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var viewpointChangedListener: UITableViewDropCoordinator!
    private var selectedFeature: AGSFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAndSyncFeaturesViewController"]
    }
}
