// Copyright 2017 Esri.
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

class FormatCoordinatesViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet private var mapView: AGSMapView!
    
    private weak var tableViewController: FormatCoordinatesTableViewController?
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    var point = AGSPoint(x: 0, y: 0, spatialReference: .webMercator()) {
        didSet {
            // display a graphic at the point
            displayGraphicAtPoint(point)
            // populate the coordinate strings for the new point
            tableViewController?.point = point
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "FormatCoordinatesViewController",
            "FormatCoordinatesTableViewController"
        ]
        
        //initializer map with basemap
        let map = AGSMap(basemap: .imagery())
        
        //assign map to map view
        mapView.map = map
        
        //add graphics overlay to the map view
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        //touch delegate for map view
        mapView.touchDelegate = self
        
        //add initial graphic
        displayGraphicAtPoint(point)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? FormatCoordinatesTableViewController {
            self.tableViewController = tableViewController
            tableViewController.point = point
            tableViewController.changeHandler = { [weak self] point in
                self?.point = point
            }
        }
    }
    
    private func displayGraphicAtPoint(_ point: AGSPoint) {
        //remove previous graphic from graphics overlay
        graphicsOverlay.graphics.removeAllObjects()
        
        //add graphic at tapped location
        let symbol = AGSSimpleMarkerSymbol(style: .cross, color: .yellow, size: 20)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        graphicsOverlay.graphics.add(graphic)
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // update the point with the tapped location
        point = mapPoint
    }
}
