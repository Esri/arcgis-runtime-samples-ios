// Copyright 2016 Esri.
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

class SetViewpointViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    
    private var map: AGSMap!
    
    private var griffithParkGeometry: AGSPolygon!
    private var londonCoordinate: AGSPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map with imagery basemap
        self.map = AGSMap(basemap: .imageryWithLabels())
        
        //assign the map to the mapview
        self.mapView.map = self.map
        
        //create a graphicsOverlay to show the graphics
        let graphicsOverlay = AGSGraphicsOverlay()
        
        self.londonCoordinate = AGSPoint(x: 0.1275, y: 51.5072, spatialReference: .wgs84())
        
        if let griffithParkGeometry = geometryFromTextFile(filename: "GriffithParkJson") {
            self.griffithParkGeometry = griffithParkGeometry as? AGSPolygon
            let griffithParkSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.solid, color: UIColor(red: 0, green: 0.5, blue: 0, alpha: 0.7), outline: nil)
            let griffithParkGraphic = AGSGraphic(geometry: griffithParkGeometry, symbol: griffithParkSymbol, attributes: nil)
            graphicsOverlay.graphics.add(griffithParkGraphic)
        }

        self.mapView.graphicsOverlays.add(graphicsOverlay)
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SetViewpointViewController"]
    }
    
    private func geometryFromTextFile(filename: String) -> AGSGeometry? {
        if let fileURL = Bundle.main.url(forResource: filename, withExtension: "txt"),
            let data = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let geometry = try? AGSGeometry.fromJSON(jsonObject) {
            return geometry as? AGSGeometry
        }
        return nil
    }

    // MARK: - Actions
    
    @IBAction private func valueChanged(_ control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            self.mapView.setViewpointGeometry(self.griffithParkGeometry, padding: 50, completion: nil)
        case 1:
            self.mapView.setViewpointCenter(self.londonCoordinate, scale: 40000, completion: nil)
        case 2:
            let currentScale = self.mapView.mapScale
            let targetScale = currentScale / 2.5 //zoom in
            let currentCenter = self.mapView.visibleArea!.extent.center
            self.mapView.setViewpoint(AGSViewpoint(center: currentCenter, scale: targetScale), duration: 5, curve: AGSAnimationCurve.easeInOutSine) { (finishedWithoutInterruption) in
                if finishedWithoutInterruption {
                    self.mapView.setViewpoint(AGSViewpoint(center: currentCenter, scale: currentScale), duration: 5, curve: .easeInOutSine)
                }
            }
        default:
            print("Never should get here")
        }
    }
}
