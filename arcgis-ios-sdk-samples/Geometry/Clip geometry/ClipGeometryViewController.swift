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
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Create a map with a topographic basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            // Add the graphics overlays to the map view.
            mapView.graphicsOverlays.addObjects(from: [coloradoGraphicsOverlay, envelopesGraphicsOverlay, clippedGraphicsOverlay])
            // Set the viewpoint to the extent of the Colorado geometry.
            mapView.setViewpointGeometry(coloradoGraphic.geometry!, padding: 100)
        }
    }
    
    // MARK: Instance properties
    
    /// A Boolean value indicating whether the geometries are clipped.
    private var geometriesAreClipped = false
    
    /// The unclipped graphic of Colorado.
    private var coloradoGraphic: AGSGraphic {
        coloradoGraphicsOverlay.graphics.firstObject as! AGSGraphic
    }
    
    /// The overlay for displaying the graphic of Colorado.
    private let coloradoGraphicsOverlay: AGSGraphicsOverlay = {
        // An envelope approximating the boundary of Colorado.
        let coloradoGeometry = AGSEnvelope(
            xMin: -11362327.128340,
            yMin: 5012861.290274,
            xMax: -12138232.018408,
            yMax: 4441198.773776,
            spatialReference: .webMercator()
        )
        
        // A semi-transparent blue color for the fill.
        let fillColor = UIColor.blue.withAlphaComponent(0.2)
        
        // The fill symbol for displaying Colorado.
        let fillSymbol = AGSSimpleFillSymbol(
            style: .solid,
            color: fillColor,
            outline: AGSSimpleLineSymbol(style: .solid, color: .blue, width: 2)
        )
        
        // Create a graphic from the geometry and symbol representing Colorado.
        let coloradoGraphic = AGSGraphic(geometry: coloradoGeometry, symbol: fillSymbol)
        
        // Create a graphics overlay.
        let coloradoGraphicsOverlay = AGSGraphicsOverlay()
        // Add the Colorado graphic to its overlay.
        coloradoGraphicsOverlay.graphics.add(coloradoGraphic)
        return coloradoGraphicsOverlay
    }()
    
    /// The graphics overlay containing clipped graphics.
    private let clippedGraphicsOverlay = AGSGraphicsOverlay()
    
    /// The overlay for displaying the other envelopes.
    private let envelopesGraphicsOverlay: AGSGraphicsOverlay = {
        // An envelope outside Colorado.
        let outsideEnvelope = AGSEnvelope(
            xMin: -11858344.321294,
            yMin: 5147942.225174,
            xMax: -12201990.219681,
            yMax: 5297071.577304,
            spatialReference: .webMercator()
        )
        
        // An envelope intersecting Colorado.
        let intersectingEnvelope = AGSEnvelope(
            xMin: -11962086.479298,
            yMin: 4566553.881363,
            xMax: -12260345.183558,
            yMax: 4332053.378376,
            spatialReference: .webMercator()
        )
        
        // An envelope inside Colorado.
        let containedEnvelope = AGSEnvelope(
            xMin: -11655182.595204,
            yMin: 4741618.772994,
            xMax: -11431488.567009,
            yMax: 4593570.068343,
            spatialReference: .webMercator()
        )
        
        // A dotted red outline symbol.
        let redOutline = AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
        
        // The envelopes in the order we want to display them.
        let envelopes = [outsideEnvelope, intersectingEnvelope, containedEnvelope]
        
        // The graphics for the envelopes with the red outline symbol.
        let graphics = envelopes.map { AGSGraphic(geometry: $0, symbol: redOutline) }
        
        let envelopesOverlay = AGSGraphicsOverlay()
        // Add the graphics to the overlay.
        envelopesOverlay.graphics.addObjects(from: graphics)
        return envelopesOverlay
    }()
    
    // MARK: Actions
    
    /// Clip geometries and add resulting graphics.
    private func clipGeometries() {
        // Hides the Colorado graphic.
        coloradoGraphic.isVisible = false
        
        let coloradoGeometry = coloradoGraphic.geometry!
        let coloradoSymbol = coloradoGraphic.symbol!
        
        // Clip Colorado's geometry to each envelope.
        let clippedGraphics: [AGSGraphic] = envelopesGraphicsOverlay.graphics.map { graphic in
            let envelope = (graphic as! AGSGraphic).geometry as! AGSEnvelope
            // Use the geometry engine to create a new geometry for the area of
            // Colorado that overlaps the given envelope.
            let clippedGeometry = AGSGeometryEngine.clipGeometry(coloradoGeometry, with: envelope)
            // Create and return the clipped graphic from the clipped geometry
            // if there is an overlap.
            return AGSGraphic(geometry: clippedGeometry, symbol: coloradoSymbol)
        }
        // Add the clipped graphics.
        clippedGraphicsOverlay.graphics.addObjects(from: clippedGraphics)
    }
    
    /// Remove all clipped graphics.
    private func reset() {
        clippedGraphicsOverlay.graphics.removeAllObjects()
        coloradoGraphic.isVisible = true
    }
    
    @IBAction func clipGeometry(_ sender: UIBarButtonItem) {
        if geometriesAreClipped {
            reset()
        } else {
            clipGeometries()
        }
        geometriesAreClipped.toggle()
        // Set button title based on whether the geometries are clipped.
        sender.title = geometriesAreClipped ? "Reset" : "Clip"
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ClipGeometryViewController"]
    }
}
