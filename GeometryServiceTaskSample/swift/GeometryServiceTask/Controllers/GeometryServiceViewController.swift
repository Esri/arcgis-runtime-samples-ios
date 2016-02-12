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

let kBaseMapService = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
let kGeometryBufferService = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Geometry/GeometryServer/buffer"

let kesriSRUnit_SurveyMile = 9035
let kesriSRUnit_Meter =	9001

let kWebMercator:UInt = 102100

class GeometryServiceViewController: UIViewController, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSGeometryServiceTaskDelegate {
    
    @IBOutlet weak var statusLabel:UILabel!
    @IBOutlet weak var mapView:AGSMapView!
    
    var graphicsLayer:AGSGraphicsLayer!
    var geometryArray:[AGSGeometry]!
    var pushpins:[AGSGraphic]!
    var numPoints:Int = 0
    var gst:AGSGeometryServiceTask!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // assign the mapView's delegate to self so we can respond to appropriate events
        self.mapView.layerDelegate = self
        self.mapView.touchDelegate = self
        
        // Create map service info with URL of base map
        let msi = AGSMapServiceInfo(URL: NSURL(string: kBaseMapService), credential: nil)
        
        // Create the base layer
        let baseLayer = AGSTiledMapServiceLayer(mapServiceInfo: msi)
        
        // Add base layer to the mapView
        self.mapView.addMapLayer(baseLayer, withName:"baseLayer")
        
        // initialize the graphics layer
        self.graphicsLayer = AGSGraphicsLayer()
        
        // Add the graphics layer to the mapView
        self.mapView.addMapLayer(self.graphicsLayer, withName:"graphicsLayer")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSGeometryServiceTaskDelegate Methods
    
    func geometryServiceTask(geometryServiceTask: AGSGeometryServiceTask!, operation op: NSOperation!, didReturnBufferedGeometries bufferedGeometries: [AnyObject]!) {
    
        UIAlertView(title: "Results", message: "Returned \(bufferedGeometries.count) buffered geometries", delegate: self, cancelButtonTitle: "Ok").show()
        
        self.graphicsLayer.removeAllGraphics()
        self.graphicsLayer.refresh()
        
        // Create a SFS for the inner buffer zone
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline.color = UIColor.darkGrayColor()
        
        // Create a SFS for the outer buffer zone
        let outerSymbol = AGSSimpleFillSymbol()
        outerSymbol.color = UIColor.yellowColor().colorWithAlphaComponent(0.25)
        outerSymbol.outline.color = UIColor.darkGrayColor()
        
        // counter to help us determine if the geometry returned is inner/outer
        var i = 0
        
        // NOTE: the bufferedGeometries returned are in order based on buffer distance...
        //
        // so if you clicked 3 points, the order would be:
        //
        // objectAtIndex		bufferedGeometry
        //
        //		0				pt1 buffered at 100m
        //		1				pt2 buffered at 100m
        //		2				pt3 buffered at 100m
        //		3				pt1 buffered at 300m
        //		4				pt2 buffered at 300m
        //		5				pt3 buffered at 300m
        for g in bufferedGeometries as! [AGSGeometry] {
            
            // initialize the graphic for geometry
            let graphic = AGSGraphic(geometry: g, symbol:nil, attributes:nil)
            
            // since we have 2 buffer distances, we know that 0-2 will be 100m buffer and 3-5 will be 300m buffer
            if i < bufferedGeometries.count/2 {
                graphic.symbol = innerSymbol
            }
            else {
                graphic.symbol = outerSymbol
            }
            
            // add graphic to the graphic layer
            self.graphicsLayer.addGraphic(graphic)
            
            // release our alloc'd graphic
            
            // increment counter so we know which index we are at
            i++
        }
        
        // get rid of the pushpins that were marking our points
        if self.pushpins != nil {
            for pushpin in self.pushpins as [AGSGraphic] {
                self.graphicsLayer.removeGraphic(pushpin)
            }
            self.pushpins = nil
        }
        
        // let the graphics layer know it has new graphics to draw
        self.graphicsLayer.refresh()
    }
    
    // Handle the case where the buffer task fails
    func geometryServiceTask(geometryServiceTask: AGSGeometryServiceTask!, operation op: NSOperation!, didFailBufferWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: self, cancelButtonTitle: nil).show()
    }
    
    //MARK: - AGSMapViewTouchDelegate methods
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
    
        // create our geometry array if needed
        if self.geometryArray == nil {
            self.geometryArray = [AGSGeometry]()
        }
        
        // add user-clicked point to the geometry array
        self.geometryArray.append(mappoint)
        
        // create pushpins array if needed
        if self.pushpins == nil {
            self.pushpins = [AGSGraphic]()
        }
        
        // create a PictureMarkerSymbol (pushpin)
        let pt = AGSPictureMarkerSymbol(imageNamed: "pushpin.png")
        
        // this offset is to line the symbol up with the map was actually clicked
        pt.offset = CGPointMake(8,18)
        
        // init pushpin with the AGSPictureMarkerSymbol we just created
        let pushpin = AGSGraphic(geometry: mappoint, symbol:pt, attributes:nil)
        
        // add pushpin to our array
        self.pushpins.append(pushpin)
        
        // add pushpin to graphics layer
        self.graphicsLayer.addGraphic(pushpin)
        
        
        // let the graphics layer know it needs to redraw
        self.graphicsLayer.refresh()
        
        // increment the number of points the user has clicked
        self.numPoints++
        
        // Update label with number of points clicked
        self.statusLabel.text = "\(self.numPoints) point(s) selected"
    }
    
    //MARK: - AGSMapViewLayerDelegate methods
    
    // Method fired when mapView has finished loading
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        // zoom into california
        let env = AGSEnvelope(xmin: -13045302.192914002, ymin:4034680.7648891876, xmax:-13043773.452348258, ymax:4036878.3294524443, spatialReference:AGSSpatialReference.webMercatorSpatialReference())
        self.mapView.zoomToEnvelope(env, animated:true)
    }
    
    //MARK: Actions
    
    @IBAction func clearGraphicsBtnClicked(sender:AnyObject) {
        
        if self.geometryArray != nil {
            // remove previously buffered geometries
            self.geometryArray.removeAll(keepCapacity: false)
        }
        
        // clear the graphics layer
        self.graphicsLayer.removeAllGraphics()
        
        // tell the graphics layer that we have modified graphics
        // and it needs to be redrawn
        self.graphicsLayer.refresh()
        
        // reset the number of clicked points
        self.numPoints = 0
        
        // reset our "directions" label
        self.statusLabel.text = "Click points to buffer around"
    }
    
    
    @IBAction func goBtnClicked(sender:AnyObject) {
    
        // Make sure the user has clicked at least 1 point
        if self.geometryArray.count == 0 {
            UIAlertView(title: "Error", message: "Please click on at least 1 point", delegate: self, cancelButtonTitle: "Ok").show()
            return
        }
        
        
        self.gst = AGSGeometryServiceTask(URL: NSURL(string: kGeometryBufferService))
        
        let sr = AGSSpatialReference(WKID: kWebMercator)
        
        // assign the delegate so we can respond to AGSGeometryServiceTaskDelegate methods
        self.gst.delegate = self
        
        let bufferParams = AGSBufferParameters()
        
        // set the units to buffer by to meters
        bufferParams.unit = AGSSRUnit.UnitMeter
        bufferParams.bufferSpatialReference = sr
        
        // set our buffer distances to 100m and 300m respectively
        bufferParams.distances = [100, 300]
        
        // assign the geometries to be buffered...
        // self.geometryArray contains the points we clicked
        bufferParams.geometries = self.geometryArray
        bufferParams.outSpatialReference = sr
        bufferParams.unionResults = false
        
        // execute the task
        self.gst.bufferWithParameters(bufferParams)
        
        // IMPORTANT: since we alloc'd/init'd bufferParams and gst
        // we must explicitly release them
    
    }
}
