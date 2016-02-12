//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSMapViewLayerDelegate, AGSRouteTaskDelegate, AGSMapViewTouchDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var prevBtn: UIBarButtonItem!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    @IBOutlet weak var reorderBtn: UIBarButtonItem!
    
    var graphicsLayerStops:AGSGraphicsLayer!
    var graphicsLayerRoute:AGSGraphicsLayer!
    var routeTask:AGSRouteTask!
    var routeTaskParams:AGSRouteTaskParameters!
    var currentDirectionGraphic:AGSDirectionGraphic!
    var routeResult:AGSRouteResult!
    var lastStop:AGSGraphic!
    var isExecuting = false
    var routeGraphic:AGSGraphic!
    var numStops:UInt = 0
    var directionIndex:Int = 0
    var reorderStops = false
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.showMagnifierOnTapAndHold = true
        self.mapView.allowMagnifierToPanMap = false
        self.mapView.layerDelegate = self
        
        
        
        // Load a tiled map service
        self.mapView.addMapLayer(AGSLocalTiledLayer(name: "SanFrancisco.tpk"))
        
        // Setup the route task
        self.routeTask = try! AGSRouteTask(databaseName: "RuntimeSanFrancisco", network:"Streets_ND")

        // assign delegate to this view controller
        self.routeTask.delegate = self
        
        // kick off asynchronous method to retrieve default parameters
        // for the route task
        self.routeTask.retrieveDefaultRouteTaskParameters()
        
        
        
        // add graphics layer for displaying the route
        let cs = AGSCompositeSymbol()
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor.yellowColor()
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor.blueColor()
        sls2.style = .Solid
        sls2.width = 4
        cs.addSymbol(sls2)
        self.graphicsLayerRoute = AGSGraphicsLayer()
        self.graphicsLayerRoute.renderer = AGSSimpleRenderer(symbol: cs)
        self.mapView.addMapLayer(self.graphicsLayerRoute, withName:"Route")
        
        // add graphics layer for displaying the stops
        self.graphicsLayerStops = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayerStops, withName:"Stops")
        
        // initialize stop counter
        self.numStops = 0
        
        
        // update our banner
        self.updateDirectionsLabel("Tap & hold on the map to add stops")
        self.directionsLabel.hidden = false
        
        self.mapView.touchDelegate = self
        self.isExecuting = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        self.lastStop = self.addStop(mappoint)
        if self.graphicsLayerStops.graphics.count > 1 {
            self.isExecuting = true
            self.solveRoute()
        }
    }
    
    func mapView(mapView: AGSMapView!, didMoveTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        if self.isExecuting {
            return
        }
        self.lastStop.geometry = mappoint
        if self.graphicsLayerStops.graphics.count < 2 {
            return
        }
        self.isExecuting = true
        self.solveRoute()
    }
    
    func mapView(mapView: AGSMapView!, didEndTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        if self.graphicsLayerStops.graphics.count < 2 {
            self.reorderBtn.enabled = false
        }
        else {
            self.reorderBtn.enabled = true
        }
    }
    
    //MARK: - AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        let museumOfMA = AGSPoint(fromDecimalDegreesString: "37.785 , -122.400", withSpatialReference:AGSSpatialReference.wgs84SpatialReference())
        self.addStop((AGSGeometryEngine.defaultGeometryEngine().projectGeometry(museumOfMA, toSpatialReference: self.mapView.spatialReference)) as! AGSPoint)
        
        if self.routeTaskParams != nil {
            self.routeTaskParams.outSpatialReference = self.mapView.spatialReference;
        }
        
        mapView.zoomIn(false);
    }
    
    //MARK: - AGSRouteTaskDelegate
    
    //
    // we got the default parameters from the service
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didRetrieveDefaultRouteTaskParameters routeParams: AGSRouteTaskParameters!) {
        self.routeTaskParams = routeParams
        
        self.routeTaskParams.returnRouteGraphics = true
        
        // this returns turn-by-turn directions
        self.routeTaskParams.returnDirections = true
        
        self.routeTaskParams.findBestSequence = false
        
        self.routeTaskParams.impedanceAttributeName = "Minutes"
        self.routeTaskParams.accumulateAttributeNames = ["Meters", "Minutes"]
        
        // since we used "findBestSequence" we need to
        // get the newly reordered stops
        self.routeTaskParams.returnStopGraphics = false
        
        // ensure the graphics are returned in our map's spatial reference
        self.routeTaskParams.outSpatialReference = self.mapView.spatialReference
        
        // let's ignore invalid locations
        self.routeTaskParams.ignoreInvalidLocations = true
    }
    
    
    //
    // an error was encountered while getting defaults
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didFailToRetrieveDefaultRouteTaskParametersWithError error: NSError!) {
        // Create an alert to let the user know the retrieval failed
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIAlertView(title: "Error", message: "Failed to retrieve default route parameters", delegate: nil, cancelButtonTitle: "OK").show()
            print("Failed to retrieve default route parameters: \(error)")
        })
    }
    
    
    //
    // route was solved
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didSolveWithResult routeTaskResult: AGSRouteTaskResult!) {
        
        // update our banner with status
        self.updateDirectionsLabel("Routing completed")
        
        // we know that we are only dealing with 1 route...
        self.routeResult = routeTaskResult.routeResults.last as! AGSRouteResult
        
        let resultSummary = String(format: "%.0f mins, %.2f miles", self.routeResult.totalMinutes, self.routeResult.totalMiles)
//        var resultSummary = "\(self.routeResult.totalMinutes) mins, \(self.routeResult.totalMiles) miles"
        self.updateDirectionsLabel(resultSummary)
        
        // add the route graphic to the graphic's layer
        self.graphicsLayerRoute.removeAllGraphics()
        self.graphicsLayerRoute.addGraphic(self.routeResult.routeGraphic)
        
        
        // enable the next button so the user can traverse directions
        self.nextBtn.enabled = true
        
        if self.routeResult.stopGraphics != nil {
            self.graphicsLayerStops.removeAllGraphics()
            
            for reorderedStop in self.routeResult.stopGraphics as! [AGSStopGraphic] {
                var exists:ObjCBool = false
                let sequence = UInt(reorderedStop.attributeAsIntegerForKey("Sequence", exists: &exists))
                
                // create a composite symbol using the sequence number
                reorderedStop.symbol = self.stopSymbolWithNumber(sequence)
                
                // add the graphic
                self.graphicsLayerStops.addGraphic(reorderedStop)
            }
            
            self.routeTaskParams.findBestSequence = false
            self.routeTaskParams.returnStopGraphics = false
        }
        self.isExecuting = false
    }
    
    //
    // solve failed
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didFailSolveWithError error: NSError!) {
        self.updateDirectionsLabel("Routing failed")
        
        // the solve route failed...
        // let the user know
        
        UIAlertView(title: "Solve Route Failed", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    //MARK: - Misc
    
    //
    // create a composite symbol with a number
    //
    func stopSymbolWithNumber(stopNumber:UInt) -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        // create outline
        let sls = AGSSimpleLineSymbol()
        sls.color = UIColor.blackColor()
        sls.width = 2
        sls.style = .Solid
        
        // create main circle
        let sms = AGSSimpleMarkerSymbol()
        sms.color = UIColor.greenColor()
        sms.outline = sls
        sms.size = CGSizeMake(20, 20)
        sms.style = .Circle
        cs.addSymbol(sms)
        
        //    // add number as a text symbol
        let ts = AGSTextSymbol(text: "\(stopNumber)", color: UIColor.blackColor())
        ts.vAlignment = .Middle
        ts.hAlignment = .Center
        ts.fontSize	= 16
        cs.addSymbol(ts)
        
        return cs
    }
    
    //
    // represents the current direction
    //
    func currentDirectionSymbol() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor.whiteColor()
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor.redColor()
        sls2.style = .Dash
        sls2.width = 4
        cs.addSymbol(sls2)
        
        return cs
    }
    
    //
    // update our banner's text
    //
    func updateDirectionsLabel(newLabel:String) {
        self.directionsLabel.text = newLabel
    }
    
    func addStop(geometry:AGSPoint) -> AGSGraphic {
        
        //grab the geometry, then clear the sketch
        //Prepare symbol and attributes for the Stop/Barrier
        self.numStops++
        let symbol = self.stopSymbolWithNumber(self.numStops)
        let stopGraphic = AGSStopGraphic(geometry: geometry, symbol:symbol, attributes:nil)
        stopGraphic.sequence = self.numStops
        
        //You can set additional properties on the stop here
        //refer to the conceptual helf for Routing task
        self.graphicsLayerStops.addGraphic(stopGraphic)
        return stopGraphic
    }
    //
    // perform the route task's solve operation
    //
    
    func solveRoute() {
        self.resetDirections()
        
        var stops = [AGSStopGraphic]()
        
        // get the stop, barriers for the route task
        for graphic in self.graphicsLayerStops.graphics as! [AGSGraphic] {
            // if it's a stop graphic, add the object to stops
            if graphic is AGSStopGraphic {
                stops.append(graphic as! AGSStopGraphic)
            }
        }
        
        // set the stop and polygon barriers on the parameters object
        if stops.count > 0 {
            // update our banner
            self.updateDirectionsLabel("Routing...")
            self.routeTaskParams.setStopsWithFeatures(stops)
            // execute the route task
            self.routeTask.solveWithParameters(self.routeTaskParams)
        }
    }
    
    //
    // reset the sample so we can perform another route
    //
    func reset() {
        // set stop counter back to 0
        self.numStops = 0
        
        // remove all graphics
        self.graphicsLayerStops.removeAllGraphics()
        self.graphicsLayerRoute.removeAllGraphics()
        self.resetDirections()
        self.updateDirectionsLabel("Tap & hold on the map to add stops")
        self.reorderBtn.enabled = false
    }
    
    func resetDirections() {
        // disable the next/prev direction buttons
        // reset direction index
        self.directionIndex = 0
        self.nextBtn.enabled = false
        self.prevBtn.enabled = false
        self.graphicsLayerRoute.removeGraphic(self.currentDirectionGraphic)
    }
    
    //MARK: Actions
    
    @IBAction func resetBtnClicked(sender: AnyObject) {
        self.reset()
    }
    
    @IBAction func nextBtnClicked(sender: AnyObject) {
        self.directionIndex++
        
        // remove current direction graphic, so we can display next one
        self.graphicsLayerRoute.removeGraphic(self.currentDirectionGraphic)
        
        // get current direction and add it to the graphics layer
        let directions = self.routeResult.directions
        self.currentDirectionGraphic = directions.graphics[self.directionIndex] as! AGSDirectionGraphic
        self.currentDirectionGraphic.symbol = self.currentDirectionSymbol()
        self.graphicsLayerRoute.addGraphic(self.currentDirectionGraphic)
        
        // update banner
        self.updateDirectionsLabel(self.currentDirectionGraphic.text)
        
        self.mapView.zoomToGeometry(self.currentDirectionGraphic.geometry, withPadding:20, animated:true)
        
        // determine if we need to disable a next/prev button
        let count = self.routeResult.directions.graphics.count
        if self.directionIndex >= (count - 1) {
            self.nextBtn.enabled = false
        }
        if self.directionIndex > 0 {
            self.prevBtn.enabled = true
        }
    }
    
    @IBAction func prevBtnClicked(sender: AnyObject) {
        self.directionIndex--
        
        // remove current direction graphic, so we can display next one
        self.graphicsLayerRoute.removeGraphic(self.currentDirectionGraphic)
        
        // get next direction
        let directions = self.routeResult.directions
        self.currentDirectionGraphic = directions.graphics[self.directionIndex] as! AGSDirectionGraphic
        self.currentDirectionGraphic.symbol = self.currentDirectionSymbol()
        self.graphicsLayerRoute.addGraphic(self.currentDirectionGraphic)
        
        // update banner text
        self.updateDirectionsLabel(self.currentDirectionGraphic.text)
        
        self.mapView.zoomToGeometry(self.currentDirectionGraphic.geometry, withPadding:20, animated:true)
        
        // determine if we need to disable next/prev button
        if self.directionIndex <= 0 {
            self.prevBtn.enabled = false
        }
        if self.directionIndex < self.routeResult.directions.graphics.count - 1 {
            self.nextBtn.enabled = true
        }
    }
    
    @IBAction func routePreferenceChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.routeTaskParams.impedanceAttributeName = "Minutes"
            break;
        case 1:
            self.routeTaskParams.impedanceAttributeName = "Meters"
        default:
            break;
        }
        self.solveRoute()
    }
    
    @IBAction func reorderStops(sender: AnyObject) {
        self.routeTaskParams.findBestSequence = true
        self.routeTaskParams.preserveFirstStop = false
        self.routeTaskParams.preserveLastStop = false
        
        self.routeTaskParams.returnStopGraphics = true
        self.solveRoute()
    }
    
}
