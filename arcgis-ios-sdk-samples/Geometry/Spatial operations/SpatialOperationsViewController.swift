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

class SpatialOperationsViewController: UIViewController, OperationsListVCDelegate, UIAdaptivePresentationControllerDelegate {

    @IBOutlet var mapView: AGSMapView!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var polygon1, polygon2: AGSPolygonBuilder!
    private var resultGraphic: AGSGraphic!
    
    let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
    
    let operations = ["None", "Union", "Difference", "Symmetric Difference", "Intersection"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SpatialOperationsViewController", "OperationsListViewController"]

        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to map view
        self.mapView.map = map
        
        //add graphics overlay to map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //initial viewpoint
        let center = AGSPoint(x: -13453, y: 6710127, spatialReference: AGSSpatialReference.webMercator())
        self.mapView.setViewpointCenter(center, scale: 30000, completion: nil)
        
        //add two polygons to be used in the operations
        self.addPolygons()
    }

    private func addPolygons() {
        
        //polygon 1
        self.polygon1 = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygon1.addPointWith(x: -13960, y: 6709400)
        polygon1.addPointWith(x: -14660, y: 6710000)
        polygon1.addPointWith(x: -13760, y: 6710730)
        polygon1.addPointWith(x: -13300, y: 6710500)
        polygon1.addPointWith(x: -13160, y: 6710100)
        
        //symbol
        let fillSymbol1 = AGSSimpleFillSymbol(style: .solid, color: .blue, outline: lineSymbol)
        
        //graphic
        let polygon1Graphic = AGSGraphic(geometry: polygon1.toGeometry(), symbol: fillSymbol1, attributes: nil)
        
        // create green polygon
        // outer ring
        let outerRing = AGSMutablePart(spatialReference: AGSSpatialReference.webMercator())
        outerRing.addPointWith(x: -13060, y: 6711030)
        outerRing.addPointWith(x: -12160, y: 6710730)
        outerRing.addPointWith(x: -13160, y: 6709700)
        outerRing.addPointWith(x: -14560, y: 6710730)
        outerRing.addPointWith(x: -13060, y: 6711030)
        
        // inner ring
        let innerRing = AGSMutablePart(spatialReference: AGSSpatialReference.webMercator())
        innerRing.addPointWith(x: -13060, y: 6710910)
        innerRing.addPointWith(x: -14160, y: 6710630)
        innerRing.addPointWith(x: -13160, y: 6709900)
        innerRing.addPointWith(x: -12450, y: 6710660)
        innerRing.addPointWith(x: -13060, y: 6710910)
        
        self.polygon2 = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygon2.parts.add(outerRing)
        polygon2.parts.add(innerRing)
        
        //symbol
        let fillSymbol2 = AGSSimpleFillSymbol(style: .solid, color: .green, outline: lineSymbol)
        
        //graphic
        let polygon2Graphic = AGSGraphic(geometry: polygon2.toGeometry(), symbol: fillSymbol2, attributes: nil)
        
        //add graphics to graphics overlay
        self.graphicsOverlay.graphics.addObjects(from: [polygon1Graphic, polygon2Graphic])
    }
    
    private func performOperation(_ index: Int) {
        var resultGeometry: AGSGeometry
        
        switch index {
            
        case 1: //Union
            resultGeometry = AGSGeometryEngine.union(ofGeometry1: self.polygon1.toGeometry(), geometry2: self.polygon2.toGeometry())!
            
        case 2: //Difference
            resultGeometry = AGSGeometryEngine.difference(ofGeometry1: self.polygon2.toGeometry(), geometry2: self.polygon1.toGeometry())!
            
        case 3: //Symmetric difference
            resultGeometry = AGSGeometryEngine.symmetricDifference(ofGeometry1: self.polygon2.toGeometry(), geometry2: self.polygon1.toGeometry())!
            
        default: //Intersection
            resultGeometry = AGSGeometryEngine.intersection(ofGeometry1: self.polygon1.toGeometry(), geometry2: self.polygon2.toGeometry())!
        }
        
        //using red fill symbol for result with black border
        let symbol = AGSSimpleFillSymbol(style: .solid, color: .red, outline: lineSymbol)
        
        //create result graphic if not present
        if self.resultGraphic == nil {
            self.resultGraphic = AGSGraphic(geometry: resultGeometry, symbol: symbol, attributes: nil)
            self.graphicsOverlay.graphics.add(self.resultGraphic)
        }
            //update the geometry if already present
        else {
            self.resultGraphic.geometry = resultGeometry
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OperationsListSegue" {
            let controller = segue.destination as! OperationsListViewController
            controller.delegate = self
            controller.operations = self.operations
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 200, height: 200)
        }
    }
    
    //MARK: - OperationsListVCDelegate
    
    func operationsListViewController(_ operationsListViewController: OperationsListViewController, didSelectOperation index: Int) {
        
        if index == 0 {
            if self.resultGraphic != nil {
                self.graphicsOverlay.graphics.remove(self.resultGraphic)
                self.resultGraphic = nil
            }
        }
        else {
            self.performOperation(index)
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
}
