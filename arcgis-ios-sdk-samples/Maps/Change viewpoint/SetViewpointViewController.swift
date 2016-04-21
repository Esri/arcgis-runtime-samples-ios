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
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var segmentedControl:UISegmentedControl!
    
    private var map:AGSMap!
    
    private var griffithParkGeometry:AGSPolygon!
    private var londonCoordinate:AGSPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map with imagery basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabelsBasemap())
        
        //assign the map to the mapview
        self.mapView.map = self.map
        
        //create a graphicsOverlay to show the graphics
        let graphicsOverlay = AGSGraphicsOverlay()
        
        self.londonCoordinate = AGSPoint(x: 0.1275, y: 51.5072, spatialReference: AGSSpatialReference.WGS84())
        
        if let griffithParkGeometry = self.geometryFromTextFile("GriffithParkJson") {
            self.griffithParkGeometry = griffithParkGeometry as! AGSPolygon
            let griffithParkSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.Solid, color: UIColor(red: 0, green: 0.5, blue: 0, alpha: 0.7), outline: nil)
            let griffithParkGraphic = AGSGraphic(geometry: griffithParkGeometry, symbol: griffithParkSymbol)
            graphicsOverlay.graphics.addObject(griffithParkGraphic)
        }
        

        self.mapView.graphicsOverlays.addObject(graphicsOverlay)
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SetViewpointViewController"]

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func geometryFromTextFile(filename:String) -> AGSGeometry? {
        if let filepath = NSBundle.mainBundle().pathForResource(filename, ofType: "txt") {
            if let jsonString = try? String(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) {
                let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                let dictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())) as! [NSObject:AnyObject]
                let geometry = AGSGeometry.fromJSON(dictionary) as! AGSGeometry
                return geometry
            }
        }
        
        return nil
    }

    //MARK: - Actions
    
    @IBAction private func valueChanged(control:UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            self.mapView.setViewpointGeometry(self.griffithParkGeometry, padding: 50, completion: nil)
        case 1:
            self.mapView.setViewpointCenter(self.londonCoordinate, scale: 40000, completion: nil)
        case 2:
            let currentScale = self.mapView.mapScale
            let targetScale = currentScale / 2.5 //zoom in
            let currentCenter = self.mapView.visibleArea!.extent.center
            self.mapView.setViewpoint(AGSViewpoint(center: currentCenter, scale: targetScale), duration: 5, curve: AGSAnimationCurve.EaseInOutSine, completion: { (finishedWithoutInterruption) -> Void in
                print(finishedWithoutInterruption)
                if(finishedWithoutInterruption){
                    self.mapView.setViewpoint(AGSViewpoint(center: currentCenter, scale: currentScale), duration: 5, curve: AGSAnimationCurve.EaseInOutSine, completion:  nil);
                }
            })
        default:
            print("Never should get here")
            
            
        }
        
    }
}
