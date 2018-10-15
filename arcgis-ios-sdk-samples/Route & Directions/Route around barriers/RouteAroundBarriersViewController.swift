//
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

class RouteAroundBarriersViewController: UIViewController, AGSGeoViewTouchDelegate, UIAdaptivePresentationControllerDelegate, DirectionsListVCDelegate {
    
    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var segmentedControl:UISegmentedControl!
    @IBOutlet var routeParametersBBI:UIBarButtonItem!
    @IBOutlet var routeBBI:UIBarButtonItem!
    @IBOutlet var directionsListBBI:UIBarButtonItem!
    @IBOutlet var directionsBottomConstraint:NSLayoutConstraint!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var barrierGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var directionsGraphicsOverlay = AGSGraphicsOverlay()
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    private var isDirectionsListVisible = false
    private var directionsListViewController:DirectionsListViewController!
    
    var generatedRoute:AGSRoute! {
        didSet {
            let flag = generatedRoute != nil
            self.directionsListBBI.isEnabled = flag
            self.toggleRouteDetails(flag)
            self.directionsListViewController.route = generatedRoute
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RouteAroundBarriersViewController", "DirectionsListViewController", "RouteParametersViewController"]
        
        let map = AGSMap(basemap: .topographic())
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, directionsGraphicsOverlay, barrierGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //get default parameters
        self.getDefaultParameters()
        
        //hide directions list
        self.toggleRouteDetails(false)
    }

    //MARK: - Route logic
    
    func getDefaultParameters() {
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                self?.routeParameters = params
                //enable bar button item
                self?.routeParametersBBI.isEnabled = true
            }
        }
    }
    
    @IBAction func route() {
        //add check
        if self.routeParameters == nil || self.stopGraphicsOverlay.graphics.count < 2 {
            presentAlert(message: "Either parameters not loaded or not sufficient stops")
            return
        }
        
        SVProgressHUD.show(withStatus: "Routing")
        
        //clear routes
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        self.routeParameters.returnStops = true
        self.routeParameters.returnDirections = true
        
        //add stops
        var stops = [AGSStop]()
        for graphic in self.stopGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
            let stop = AGSStop(point: graphic.geometry as! AGSPoint)
            stop.name = "\(self.stopGraphicsOverlay.graphics.index(of: graphic)+1)"
            stops.append(stop)
        }
        self.routeParameters.clearStops()
        self.routeParameters.setStops(stops)
        
        //add barriers
        var barriers = [AGSPolygonBarrier]()
        for graphic in self.barrierGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
            let polygon = graphic.geometry as! AGSPolygon
            let barrier = AGSPolygonBarrier(polygon: polygon)
            barriers.append(barrier)
        }
        self.routeParameters.clearPolygonBarriers()
        self.routeParameters.setPolygonBarriers(barriers)
        
        self.routeTask.solveRoute(with: self.routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            if let error = error {
                self?.presentAlert(message: "\(error.localizedDescription) \((error as NSError).localizedFailureReason ?? "")")
            }
            else {
                SVProgressHUD.dismiss()
                let route = routeResult!.routes[0]
                let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self!.routeSymbol(), attributes: nil)
                self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                self?.generatedRoute = route
            }
        }
    }
    
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        return symbol
    }
    
    func directionSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .dashDot, color: .orange, width: 5)
        return symbol
    }
    
    private func symbolForStopGraphic(withIndex index: Int) -> AGSSymbol {
        let markerImage = UIImage(named: "BlueMarker")!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        
        let textSymbol = AGSTextSymbol(text: "\(index)", color: .white, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
        textSymbol.offsetY = markerSymbol.offsetY
        
        let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
        
        return compositeSymbol
    }
    
    func barrierSymbol() -> AGSSimpleFillSymbol {
        return AGSSimpleFillSymbol(style: .diagonalCross, color: .red, outline: nil)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //normalize geometry
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: mapPoint)!
        
        if segmentedControl.selectedSegmentIndex == 0 {
            //create a graphic for stop and add to the graphics overlay
            let graphicsCount = self.stopGraphicsOverlay.graphics.count
            let symbol = self.symbolForStopGraphic(withIndex: graphicsCount+1)
            let graphic = AGSGraphic(geometry: normalizedPoint, symbol: symbol, attributes: nil)
            self.stopGraphicsOverlay.graphics.add(graphic)
            
            //enable route button
            if graphicsCount > 0 {
                self.routeBBI.isEnabled = true
            }
        }
        else {
            let bufferedGeometry = AGSGeometryEngine.bufferGeometry(normalizedPoint, byDistance: 500)
            let symbol = self.barrierSymbol()
            let graphic = AGSGraphic(geometry: bufferedGeometry, symbol: symbol, attributes: nil)
            self.barrierGraphicsOverlay.graphics.add(graphic)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func clearAction() {
        if segmentedControl.selectedSegmentIndex == 0 {
            self.stopGraphicsOverlay.graphics.removeAllObjects()
            self.routeBBI.isEnabled = false
        }
        else {
            self.barrierGraphicsOverlay.graphics.removeAllObjects()
        }
    }
    
    @IBAction func directionsListAction() {
        self.directionsBottomConstraint.constant = self.isDirectionsListVisible ? -115 : 0
        UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
            self?.view.layoutIfNeeded()
            }, completion: { [weak self] (finished) -> Void in
                self?.isDirectionsListVisible = !self!.isDirectionsListVisible
        }) 
    }
    
    func toggleRouteDetails(_ on:Bool) {
        self.directionsBottomConstraint.constant = on ? -115 : -150
        UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
            self?.view.layoutIfNeeded()
            }, completion: { [weak self] (finished) -> Void in
                if !on {
                    self?.isDirectionsListVisible = false
                }
        }) 
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RouteSettingsSegue" {
            let controller = segue.destination as! RouteParametersViewController
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 125)
            controller.routeParameters = self.routeParameters
        }
        else if segue.identifier == "DirectionsListSegue" {
            self.directionsListViewController = segue.destination as? DirectionsListViewController
            self.directionsListViewController.delegate = self
        }
    }
    
    //MARk: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    
        return .none
    }
    
    //MARK: - DirectionsListVCDelegate
    
    func directionsListViewControllerDidDeleteRoute(_ directionsListViewController: DirectionsListViewController) {
        self.generatedRoute = nil;
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
    }
    
    func directionsListViewController(_ directionsListViewController: DirectionsListViewController, didSelectDirectionManuever directionManeuver: AGSDirectionManeuver) {
        //remove previous directions
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
        
        //show the maneuver geometry on the map view
        let directionGraphic = AGSGraphic(geometry: directionManeuver.geometry!, symbol: self.directionSymbol(), attributes: nil)
        self.directionsGraphicsOverlay.graphics.add(directionGraphic)
        
        //zoom to the direction
        self.mapView.setViewpointGeometry(directionManeuver.geometry!.extent, padding: 100, completion: nil)
    }
}
