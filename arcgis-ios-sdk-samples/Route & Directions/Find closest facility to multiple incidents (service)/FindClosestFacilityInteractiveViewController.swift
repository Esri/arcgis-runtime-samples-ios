//
// Copyright © 2020 Esri.
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

class FindClosestFacilityInteractiveViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapType: .streets, latitude: 32.727, longitude: -117.1750, levelOfDetail: 12)
            mapView.touchDelegate = self
            
            createFacilitiesAndGraphics()
            mapView.graphicsOverlays.add(facilityGraphicsOverlay)
            mapView.graphicsOverlays.add(incidentGraphicsOverlay)
        }
    }
    
    private let facilityURL = URL(string: "https://static.arcgis.com/images/Symbols/SafetyHealth/Hospital.png")!
    private var facilityGraphicsOverlay = AGSGraphicsOverlay()
    private var incidentGraphicsOverlay = AGSGraphicsOverlay()
    
    private func createFacilitiesAndGraphics() {
        let facilities = [
            AGSPoint(x: -1.3042129900625112E7, y: 3860127.9479775648, spatialReference: .webMercator()),
            AGSPoint(x: -1.3042193400557665E7, y: 3862448.873041752, spatialReference: .webMercator()),
            AGSPoint(x: -1.3046882875518233E7, y: 3862704.9896770366, spatialReference: .webMercator()),
            AGSPoint(x: -1.3040539754780494E7, y: 3862924.5938606677, spatialReference: .webMercator()),
            AGSPoint(x: -1.3042571225655518E7, y: 3858981.773018156, spatialReference: .webMercator()),
            AGSPoint(x: -1.3039784633928463E7, y: 3856692.5980474586, spatialReference: .webMercator()),
            AGSPoint(x: -1.3049023883956768E7, y: 3861993.789732541, spatialReference: .webMercator())]
        let facilitySymbol = AGSPictureMarkerSymbol(url: facilityURL)
        facilitySymbol.height = 30
        facilitySymbol.width = 30
        
        for eachFacility in facilities {
            facilityGraphicsOverlay.graphics.add(AGSGraphic(geometry: eachFacility, symbol: facilitySymbol, attributes: .none))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindClosestFacilityInteractiveViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension FindClosestFacilityInteractiveViewController: AGSGeoViewTouchDelegate {
    
}
