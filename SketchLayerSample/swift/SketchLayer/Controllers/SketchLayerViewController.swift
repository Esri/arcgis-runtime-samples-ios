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

class SketchLayerViewController: UIViewController {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var toolbar:UIToolbar!
    var sketchToolbar:SketchToolbar!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Show magnifier to help with sketching
        self.mapView.showMagnifierOnTapAndHold = true
        
        //Tiled basemap layer
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Graphics layer to hold all sketches (points, polylines, and polygons)
        let graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(graphicsLayer, withName:"Graphics Layer")
        
        //A composite symbol for the graphics layer's renderer to symbolize the sketches
        let composite = AGSCompositeSymbol()
        let markerSymbol = AGSSimpleMarkerSymbol()
        markerSymbol.style = .Square
        markerSymbol.color = UIColor.greenColor()
        composite.addSymbol(markerSymbol)
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.grayColor()
        lineSymbol.width = 4
        composite.addSymbol(lineSymbol)
        let fillSymbol = AGSSimpleFillSymbol()
        fillSymbol.color = UIColor(red: 1, green: 1, blue: 0, alpha: 0.5)
        composite.addSymbol(fillSymbol)
        let renderer = AGSSimpleRenderer(symbol: composite)
        graphicsLayer.renderer = renderer
        
        //Sketch layer
        let sketchLayer = AGSSketchGraphicsLayer(geometry: nil)
        self.mapView.addMapLayer(sketchLayer, withName:"Sketch layer")
        
        //Helper class to manage the UI toolbar, Sketch Layer, and Graphics Layer
        //Basically, where the magic happens
        self.sketchToolbar = SketchToolbar(toolbar: self.toolbar, sketchLayer: sketchLayer, mapView: self.mapView, graphicsLayer: graphicsLayer)
        //Manhanttan, New York
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -8235886.761869, ymin:4977698.714786, xmax:-8235122.391586, ymax:4978797.497068, spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
