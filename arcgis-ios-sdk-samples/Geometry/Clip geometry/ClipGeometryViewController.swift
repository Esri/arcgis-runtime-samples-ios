// Copyright 2018 Esri
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

class ClipGeometryViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    
    /// The overlay for displaying the graphic of Colorado.
    private let coloradoOverlay = AGSGraphicsOverlay()
    
    /// The overlay for displaying the other envelopes.
    private let envelopesOverlay: AGSGraphicsOverlay = {
        /// An envelope outside Colorado.
        let outsideEnvelope = AGSEnvelope(
            xMin: -11858344.321294,
            yMin: 5147942.225174,
            xMax: -12201990.219681,
            yMax: 5297071.577304,
            spatialReference: .webMercator()
        )
        
        /// An envelope intersecting Colorado.
        let intersectingEnvelope = AGSEnvelope(
            xMin: -11962086.479298,
            yMin: 4566553.881363,
            xMax: -12260345.183558,
            yMax: 4332053.378376,
            spatialReference: .webMercator()
        )
        
        /// An envelope inside Colorado.
        let containedEnvelope = AGSEnvelope(
            xMin: -11655182.595204,
            yMin: 4741618.772994,
            xMax: -11431488.567009,
            yMax: 4593570.068343,
            spatialReference: .webMercator()
        )
        
        /// A dotted red outline symbol.
        let redOutline = AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
        
        /// The envelopes in the order we want to display them.
        let envelopes = [outsideEnvelope, intersectingEnvelope, containedEnvelope]
        
        /// The graphics for the envelopes with the red outline symbol.
        let graphics = envelopes.map { AGSGraphic(geometry: $0, symbol: redOutline) }
       
        let envelopesOverlay = AGSGraphicsOverlay()
        // add the graphics to the overlay
        envelopesOverlay.graphics.addObjects(from: graphics)
        return envelopesOverlay
    }()
    
    /// The graphic representing Colorado.
    private let coloradoGraphic: AGSGraphic = {
        /// An envelope approximating the boundary of Colorado.
        let coloradoGeometry = AGSEnvelope(
            xMin: -11362327.128340,
            yMin: 5012861.290274,
            xMax: -12138232.018408,
            yMax: 4441198.773776,
            spatialReference: .webMercator())
        
        /// A semi-transparent blue color for the fill.
        let fillColor = UIColor.blue.withAlphaComponent(0.2)
        /// The fill symbol for displaying Colorado.
        let fillSymbol = AGSSimpleFillSymbol(
            style: .solid,
            color: fillColor,
            outline: AGSSimpleLineSymbol(style: .solid, color: .blue, width: 2)
        )
        // create a graphic from the geometry and symbol
        return AGSGraphic(geometry: coloradoGeometry, symbol: fillSymbol)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ClipGeometryViewController"]
        
        // instantiate map using a basemap
        let map = AGSMap(basemap: .topographic())
        // assign the map to the map view
        mapView.map = map
        
        // add the Colorado graphic to its overlay
        coloradoOverlay.graphics.add(coloradoGraphic)

        // add the graphics overlays to the map view in the order we want them to appear
        mapView.graphicsOverlays.addObjects(from: [coloradoOverlay, envelopesOverlay])
        
        // set the initial viewpoint to the extent of the Colorado geometry, plus a margin
        mapView.setViewpointGeometry(coloradoGraphic.geometry!, padding: 100)
    }
    
    @IBAction func clipGeometry(_ sender: UIBarButtonItem) {
        // disable the clip button
        sender.isEnabled = false
        
        // hide the Colorado graphic
        coloradoGraphic.isVisible = false
        
        guard let coloradoGeometry = coloradoGraphic.geometry,
            let coloradoSymbol = coloradoGraphic.symbol else {
            return
        }
        
        for envelopeGraphic in envelopesOverlay.graphics as! [AGSGraphic] {
            if let envelope = envelopeGraphic.geometry as? AGSEnvelope,
                // use the geometry engine to get a new geometry for the area of Colorado that overlaps the envelope
                let clippedGeometry = AGSGeometryEngine.clipGeometry(coloradoGeometry, with: envelope) {
                // if there is an overlap, greate a graphic for it using the same symbol as Colorado
                let clippedGraphic = AGSGraphic(geometry: clippedGeometry, symbol: coloradoSymbol)
                // add the resultant graphic to the overlay
                coloradoOverlay.graphics.add(clippedGraphic)
            }
        }
    }
}
