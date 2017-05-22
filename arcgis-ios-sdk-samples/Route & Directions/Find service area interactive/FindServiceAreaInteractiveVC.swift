//
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

class FindServiceAreaInteractiveVC: UIViewController, AGSGeoViewTouchDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var segmentedControl:UISegmentedControl!
    @IBOutlet private var serviceAreaBBI:UIBarButtonItem!
    
    private var facilitiesGraphicsOverlay = AGSGraphicsOverlay()
    private var barriersGraphicsOverlay = AGSGraphicsOverlay()
    private var serviceAreaGraphicsOverlay = AGSGraphicsOverlay()
    private var barrierGraphic:AGSGraphic!
    private var serviceAreaTask:AGSServiceAreaTask!
    private var serviceAreaParameters:AGSServiceAreaParameters!
    
    private var barriersPolylineBuilder = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindServiceAreaInteractiveVC"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.streets())
        
        //center for initial viewpoint
        let center = AGSPoint(x: -13041154, y: 3858170, spatialReference: AGSSpatialReference.webMercator())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: center, scale: 1e5)
        
        //assign map to map view
        self.mapView.map = map
        
        //assign touch delegate as self to know when use interacted with the map view
        //Will be adding facilities and barriers on interaction
        self.mapView.touchDelegate = self
        
        //initialize service area task
        self.serviceAreaTask = AGSServiceAreaTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ServiceArea")!)
        
        //get default parameters for the task
        self.getDefaultParameters()
        
        //facility picture marker symbol
        let facilitySymbol = AGSPictureMarkerSymbol(image: UIImage(named: "Facility")!)
        
        //offset symbol in Y to align image properly
        facilitySymbol.offsetY = 21
        
        //assign renderer on facilities graphics overlay using the picture marker symbol
        self.facilitiesGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: facilitySymbol)
        
        //barrier symbol
        let barrierSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.secondaryBlue(), width: 3)
        
        //set symbol on barrier graphics overlay using renderer
        self.barriersGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: barrierSymbol)
        
        //Barrier graphic for polyline barrier
        //will update the geometry on user interaction
        self.barrierGraphic = AGSGraphic(geometry: self.barriersPolylineBuilder.toGeometry(), symbol: nil, attributes: nil)
        
        //add barrier graphic to overlay
        self.barriersGraphicsOverlay.graphics.add(self.barrierGraphic)
        
        //add graphicOverlays to the map. One for facilities, barriers and service areas
        self.mapView.graphicsOverlays.addObjects(from: [self.serviceAreaGraphicsOverlay, self.barriersGraphicsOverlay, self.facilitiesGraphicsOverlay])
    }
    
    private func getDefaultParameters() {
        
        //get default parameters
        self.serviceAreaTask.defaultServiceAreaParameters { [weak self] (parameters: AGSServiceAreaParameters?, error: Error?) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: "Error getting default parameters:: \(error?.localizedDescription)", maskType: .gradient)
                return
            }
            
            //keep a reference to the default parameters to be used later
            self?.serviceAreaParameters = parameters
            
            //enable service area bar button item
            self?.serviceAreaBBI.isEnabled = true
        }
    }
    
    @IBAction private func serviceArea() {
        
        //remove previously added service areas
        self.serviceAreaGraphicsOverlay.graphics.removeAllObjects()
        
        //check if at least a single facility is added
        if self.facilitiesGraphicsOverlay.graphics.count == 0 {
            
            SVProgressHUD.showInfo(withStatus: "At least one facility is required", maskType: .gradient)
            
            return
        }
        
        //clear previously added facilities and barriers from parameters
        self.serviceAreaParameters.clearFacilities()
        self.serviceAreaParameters.clearPolylineBarriers()
        
        //add facilities
        var facilities = [AGSServiceAreaFacility]()
        
        //for each graphic in facilities graphicsOverlay add a facility to the parameters
        for graphic in self.facilitiesGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
            
            let point = graphic.geometry as! AGSPoint
            let facility = AGSServiceAreaFacility(point: point)
            facilities.append(facility)
        }
        self.serviceAreaParameters.setFacilities(facilities)
        
        //add barriers
        if let polyline = self.barrierGraphic.geometry as? AGSPolyline, polyline.parts[0].pointCount > 1 {
            
            let polylineBarrier = AGSPolylineBarrier(polyline: polyline)
            self.serviceAreaParameters.setPolylineBarriers([polylineBarrier])
        }
        
        //solve for service area
        self.serviceAreaTask.solveServiceArea(with: self.serviceAreaParameters) { [weak self] (result: AGSServiceAreaResult?, error: Error?) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: "Error solving service area:: \(error?.localizedDescription)", maskType: .gradient)
                return
            }
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            //for each facility
            for i in 0...facilities.count {
                
                //add resulting polygons as graphics to the overlay
                if let polygons = result?.resultPolygons(atFacilityIndex: i) {
                    for polygon in polygons {
                        
                        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor(red: 0, green: 0.4, blue: 0, alpha: 0.5), width: 2)
                        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.5), outline: lineSymbol)
                        let graphic = AGSGraphic(geometry: polygon.geometry, symbol: fillSymbol, attributes: nil)
                        self?.serviceAreaGraphicsOverlay.graphics.add(graphic)
                    }
                }
            }
        }
    }
    
    @IBAction private func clearAction() {
        
        //remove all existing graphics in service area and facilities graphics overlays
        self.serviceAreaGraphicsOverlay.graphics.removeAllObjects()
        self.facilitiesGraphicsOverlay.graphics.removeAllObjects()
        
        //for barriers, re-initialize the polyline builder
        self.barriersPolylineBuilder = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
        
        //and assign as geometry to the graphic
        self.barrierGraphic.geometry = self.barriersPolylineBuilder.toGeometry()
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            
            //facilities selected
            let graphic = AGSGraphic(geometry: mapPoint, symbol: nil, attributes: nil)
            self.facilitiesGraphicsOverlay.graphics.add(graphic)
        }
        else {
            
            //barriers selected
            //add point to barrier builder
            self.barriersPolylineBuilder.addPointWith(x: mapPoint.x, y: mapPoint.y)
            
            //update the geometry of the barrier graphic
            self.barrierGraphic.geometry = self.barriersPolylineBuilder.toGeometry()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
