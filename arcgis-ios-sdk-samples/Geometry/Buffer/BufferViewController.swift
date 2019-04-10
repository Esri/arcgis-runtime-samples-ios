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

class BufferViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    /// The radius to pass into the buffer functions.
    private var bufferDistance: Measurement<UnitLength> = Measurement(value: 500, unit: .miles)
    
    /// The overlay for displaying the location of the tap point.
    /// White crosses.
    private let tapLocationsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let symbol = AGSSimpleMarkerSymbol(style: .cross, color: .white, size: 14)
        overlay.renderer = AGSSimpleRenderer(symbol: symbol)
        return overlay
    }()
    
    /// The overlay for displaying the geometries created via a planar buffer around the tap point.
    /// Red, but appears as brown when blended with the geodesic overlay.
    private let planarOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let outlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 2)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: .red, outline: outlineSymbol)
        overlay.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        overlay.opacity = 0.5
        return overlay
    }()
    
    /// The overlay for displaying the geometries created via a geodesic buffer around the tap point.
    /// Green.
    private let geodesicOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let outlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 2)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: .green, outline: outlineSymbol)
        overlay.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        overlay.opacity = 0.5
        return overlay
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "BufferViewController",
            "BufferOptionsViewController"
        ]
        
        // instantiate a map using a topo basemap
        let map = AGSMap(basemap: .topographic())
        // assign the map to the map view
        mapView.map = map
        
        // add the graphics overlays in the order we want them to draw, bottom to top
        mapView.graphicsOverlays.addObjects(from: [geodesicOverlay, planarOverlay, tapLocationsOverlay])
        
        // register to receive callbacks for pointer inputs in the map view
        mapView.touchDelegate = self
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? BufferOptionsViewController {
            // setup the options controller
            controller.delegate = self
            controller.bufferDistance = bufferDistance
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 78)
        }
    }
    
    @IBAction func clearAllAction(_ sender: UIBarButtonItem) {
        // remove the graphics from all the overlays, resetting the map view to its initial contents
        for overlay in mapView.graphicsOverlays as! [AGSGraphicsOverlay] {
            overlay.graphics.removeAllObjects()
        }
    }
}

extension BufferViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        /// The buffer radius converted to meters.
        let bufferRadiusInMeters = bufferDistance.converted(to: .meters).value
       
        // ensure that the buffer radius is a positive value
        guard bufferRadiusInMeters > 0 else {
            return
        }
        
        // create geometry for the map point buffered by the given distance in respect
        // to the projected map spatial reference system
        if let planarGeometry = AGSGeometryEngine.bufferGeometry(mapPoint, byDistance: bufferRadiusInMeters) {
            let graphic = AGSGraphic(geometry: planarGeometry, symbol: nil)
            planarOverlay.graphics.add(graphic)
        }
        
        // create geometry for the map point buffered by the given distance in respect
        // to the geodetic spatial reference system (the 3D representation of the Earth)
        if let geodesicGeometry = AGSGeometryEngine.geodeticBufferGeometry(
            mapPoint,
            distance: bufferRadiusInMeters,
            distanceUnit: .meters(),
            maxDeviation: .nan,
            curveType: .geodesic
            ) {
            let graphic = AGSGraphic(geometry: geodesicGeometry, symbol: nil)
            geodesicOverlay.graphics.add(graphic)
        }
        
        // create and add graphic symbolizing the tap point
        let pointGraphic = AGSGraphic(geometry: mapPoint, symbol: nil)
        tapLocationsOverlay.graphics.add(pointGraphic)
    }
}

extension BufferViewController: BufferOptionsViewControllerDelegate {
    func bufferOptionsViewController(_ bufferOptionsViewController: BufferOptionsViewController, bufferDistanceChangedTo bufferDistance: Measurement<UnitLength>) {
        self.bufferDistance = bufferDistance
    }
}

extension BufferViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
