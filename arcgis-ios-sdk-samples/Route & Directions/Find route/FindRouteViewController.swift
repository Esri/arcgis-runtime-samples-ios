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

class FindRouteViewController: UIViewController {
    
    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var routeBBI:UIBarButtonItem!
    @IBOutlet var directionsListBBI:UIBarButtonItem!
    
    var routeTask:AGSRouteTask!
    var routeParameters:AGSRouteParameters!
    
    var stopGraphicsOverlay = AGSGraphicsOverlay()
    var routeGraphicsOverlay = AGSGraphicsOverlay()
    
    var stop1Geometry:AGSPoint!
    var stop2Geometry:AGSPoint!
    
    var generatedRoute:AGSRoute! {
        didSet {
            let flag = generatedRoute != nil
            self.directionsListBBI.isEnabled = flag
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindRouteViewController", "DirectionsViewController"]
        
        //initialize map with topographic basemap
        let map = AGSMap(basemap: .topographic())
        self.mapView.map = map
        
        //add graphicsOverlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13041154.715252, y: 3858170.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //get default parameters
        self.getDefaultParameters()
    }
    
    //add hard coded stops to the map view
    func addStops() {
        self.stop1Geometry = AGSPoint(x: -13041171.537945, y: 3860988.271378, spatialReference: AGSSpatialReference(wkid: 3857))
        self.stop2Geometry = AGSPoint(x: -13041693.562570, y: 3856006.859684, spatialReference: AGSSpatialReference(wkid: 3857))
        
        let startStopGraphic = AGSGraphic(geometry: self.stop1Geometry, symbol: self.stopSymbol(withName: "Origin", textColor: .blue), attributes: nil)
        let endStopGraphic = AGSGraphic(geometry: self.stop2Geometry, symbol: self.stopSymbol(withName: "Destination", textColor: .red), attributes: nil)
        
        self.stopGraphicsOverlay.graphics.addObjects(from: [startStopGraphic, endStopGraphic])
    }
    
    //method provides a text symbol for stop with specified parameters
    func stopSymbol(withName name:String, textColor:UIColor) -> AGSTextSymbol {
        return AGSTextSymbol(text: name, color: textColor, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
    }
    
    //method provides a line symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        return symbol
    }
    
    //MARK: - Route logic
    
    //method to get the default parameters for the route task
    func getDefaultParameters() {
        
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                //on completion store the parameters
                self?.routeParameters = params
                //add stops
                self?.addStops()
                //enable bar button item
                self?.routeBBI.isEnabled = true
            }
        }
    }
    
    @IBAction func route() {
        //route only if default parameters are fetched successfully
        if self.routeParameters == nil {
            print("Default route parameters not loaded")
        }
        
        //set parameters to return directions
        self.routeParameters.returnDirections = true
        
        //clear previous routes
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        //clear previous stops
        self.routeParameters.clearStops()
        
        //set the stops
        let stop1 = AGSStop(point: self.stop1Geometry)
        stop1.name = "Origin"
        let stop2 = AGSStop(point: self.stop2Geometry)
        stop2.name = "Destination"
        self.routeParameters.setStops([stop1, stop2])
        
        self.routeTask.solveRoute(with: self.routeParameters) { (routeResult: AGSRouteResult?, error: Error?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                //show the resulting route on the map
                //also save a reference to the route object
                //in order to access directions
                self.generatedRoute = routeResult!.routes[0]
                let routeGraphic = AGSGraphic(geometry: self.generatedRoute.routeGeometry, symbol: self.routeSymbol(), attributes: nil)
                self.routeGraphicsOverlay.graphics.add(routeGraphic)
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DirectionsSegue" {
            let controller = segue.destination as! DirectionsViewController
            controller.directionManeuvers = self.generatedRoute.directionManeuvers
        }
    }
}
