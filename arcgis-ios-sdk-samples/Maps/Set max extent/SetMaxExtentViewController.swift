// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class SetMaxExtentViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // The graphics overlay used to show the extent envelope graphic.
            let graphicsOverlay = AGSGraphicsOverlay()
            graphicsOverlay.graphics.add(AGSGraphic(
                geometry: extentEnvelope,
                symbol: AGSSimpleLineSymbol(style: .dash, color: .red, width: 5)
            ))
            mapView.graphicsOverlays.add(graphicsOverlay)
        }
    }
    
    // MARK: Properties
    
    /// The envelope that represents the max extent.
    let extentEnvelope = AGSEnvelope(
        xMin: -12139393.2109,
        yMin: 4438148.7816,
        xMax: -11359277.5124,
        yMax: 5012444.0468,
        spatialReference: .webMercator()
    )
    
    // MARK: Methods
    
    /// Create a map.
    func makeMap() -> AGSMap {
        // Create a map with the streets basemap focused on Colorado.
        let map = AGSMap(basemapStyle: .arcGISStreets)
        // Set the map's max extent to an envelope of Colorado's northwest
        // and southeast corners.
        map.maxExtent = extentEnvelope
        return map
    }
    
    @IBAction func extentSwitchValueChanged(_ sender: UISwitch) {
        mapView.map!.maxExtent = sender.isOn ? extentEnvelope : nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["SetMaxExtentViewController"]
    }
}
