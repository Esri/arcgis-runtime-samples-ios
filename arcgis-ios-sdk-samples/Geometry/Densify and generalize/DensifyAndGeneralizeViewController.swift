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

class DensifyAndGeneralizeViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    /// The overlay for which to display the graphics.
    private let graphicsOverlay = AGSGraphicsOverlay()
    /// The base geometry that is densified and generalized.
    private let originalPolyline: AGSPolyline
    
    /// The graphics for displaying the points of the resultant geometry.
    private let resultPointsGraphic: AGSGraphic = {
        let graphic = AGSGraphic()
        graphic.symbol = AGSSimpleMarkerSymbol(style: .circle, color: .magenta, size: 7)
        return graphic
    }()
    
    /// The graphic for displaying the lines of the resultant geometry.
    private let resultPolylineGraphic: AGSGraphic = {
        let graphic = AGSGraphic()
        graphic.symbol = AGSSimpleLineSymbol(style: .solid, color: .magenta, width: 3)
        return graphic
    }()

    private var shouldGeneralize = false
    private var maxDeviation = 10.0
    private var shouldDensify = false
    private var maxSegmentLength = 100.0
    
    required init?(coder aDecoder: NSCoder) {
        let spatialReference = AGSSpatialReference(wkid: 32126)
        /// The base collection of points from which the original polyline and mulitpoint
        /// geometries are made.
        let collection = AGSMutablePointCollection(spatialReference: spatialReference)
        collection.addPointWith(x: 2330611.130549, y: 202360.002957)
        collection.addPointWith(x: 2330583.834672, y: 202525.984012)
        collection.addPointWith(x: 2330574.164902, y: 202691.488009)
        collection.addPointWith(x: 2330689.292623, y: 203170.045888)
        collection.addPointWith(x: 2330696.773344, y: 203317.495798)
        collection.addPointWith(x: 2330691.419723, y: 203380.917080)
        collection.addPointWith(x: 2330435.065296, y: 203816.662457)
        collection.addPointWith(x: 2330369.500800, y: 204329.861789)
        collection.addPointWith(x: 2330400.929891, y: 204712.129673)
        collection.addPointWith(x: 2330484.300447, y: 204927.797132)
        collection.addPointWith(x: 2330514.469919, y: 205000.792463)
        collection.addPointWith(x: 2330638.099138, y: 205271.601116)
        collection.addPointWith(x: 2330725.315888, y: 205631.231308)
        collection.addPointWith(x: 2330755.640702, y: 206433.354860)
        collection.addPointWith(x: 2330680.644719, y: 206660.240923)
        collection.addPointWith(x: 2330386.957926, y: 207340.947204)
        collection.addPointWith(x: 2330485.861737, y: 207742.298501)
        
        // create the base geometries
        originalPolyline = AGSPolyline(points: collection.array())
        let multipoint = AGSMultipoint(points: collection.array())
        
        // create graphics for displaying the base points and lines
        let originalPolylineGraphic = AGSGraphic(geometry: originalPolyline, symbol: AGSSimpleLineSymbol(style: .dot, color: .red, width: 3))
        let originalPointsGraphic = AGSGraphic(geometry: multipoint, symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 7))
        
        // add the graphics in the order we want them to appear, back to front
        graphicsOverlay.graphics.addObjects(from: [
            originalPointsGraphic,
            originalPolylineGraphic,
            resultPointsGraphic,
            resultPolylineGraphic
        ])
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "DensifyAndGeneralizeViewController",
            "GeneralizeSettingsViewController"
        ]

        // initialize map with basemap
        let map = AGSMap(basemap: .streetsNightVector())
        // assign map to map view
        mapView.map = map
       
        // add the graphics overlay to the map view
        mapView.graphicsOverlays.add(graphicsOverlay)
    
        // set the initial viewpoint to show the extent of the graphics
        mapView.setViewpointGeometry(originalPolyline.extent, padding: 100)
    }
    
    private func updateGraphicsForDensifyAndGeneralize() {
        var resultPolyline = originalPolyline
        
        if shouldGeneralize {
            // generalize the polyline with the specified max deviation
            resultPolyline = AGSGeometryEngine.generalizeGeometry(
                resultPolyline,
                maxDeviation: maxDeviation,
                removeDegenerateParts: true
            ) as! AGSPolyline
        }
        if shouldDensify {
            // densify the points of the polyline with the specified max segment length
            resultPolyline = AGSGeometryEngine.densifyGeometry(
                resultPolyline,
                maxSegmentLength: maxSegmentLength
            ) as! AGSPolyline
        }
        
        // get the result points in an array
        let points = resultPolyline.parts.array().flatMap { $0.points.array() }
        // create a multipoint geometry from the result points
        let resultMultipoint = AGSMultipoint(points: points)
        
        // update the result graphics with the result geometries
        resultPolylineGraphic.geometry = resultPolyline
        resultPointsGraphic.geometry = resultMultipoint
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? GeneralizeSettingsViewController {
            // fill the model values in the settings controller
            controller.shouldGeneralize = shouldGeneralize
            controller.shouldDensify = shouldDensify
            controller.maxSegmentLength = maxSegmentLength
            controller.maxDeviation = maxDeviation
            
            // register to receive value change callbacks
            controller.delegate = self
            
            // setup the controller to display as a popover
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 250)
        }
    }
}

extension DensifyAndGeneralizeViewController: GeneralizeSettingsViewControllerDelegate {
    func generalizeSettingsViewControllerDidUpdate(_ generalizeSettingsViewController: GeneralizeSettingsViewController) {
        // update the model with the new values
        shouldDensify = generalizeSettingsViewController.shouldDensify
        shouldGeneralize = generalizeSettingsViewController.shouldGeneralize
        maxSegmentLength = generalizeSettingsViewController.maxSegmentLength
        maxDeviation = generalizeSettingsViewController.maxDeviation
        
        // update the graphics for the new values
        updateGraphicsForDensifyAndGeneralize()
    }
}

extension DensifyAndGeneralizeViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
