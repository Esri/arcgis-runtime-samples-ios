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

class SpatialRelationshipContainer {
    var checked = false
    var spatialRelationship:Int!
    var name:String!
    
    init(spatialRelationship:Int, relationshipName name:String) {
        self.spatialRelationship = spatialRelationship
        self.name = name
//        super.init()
    }
}

class RelationshipViewController: UIViewController, AGSMapViewLayerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var relationshipTable:UITableView!
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var geometrySelect:UISegmentedControl!
    @IBOutlet weak var userInstructions:UILabel!
    
    var spatialRelationships:[SpatialRelationshipContainer]!
    var graphicsLayer:AGSGraphicsLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.showMagnifierOnTapAndHold = true
        self.mapView.enableWrapAround()
        self.mapView.layerDelegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        // Create a graphics layer and add it to the map
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        
        // Create a container for each of the spatial relationships
        let within = SpatialRelationshipContainer(spatialRelationship: 0, relationshipName:"Within")
        let touches = SpatialRelationshipContainer(spatialRelationship: 1, relationshipName:"Touches")
        let overlaps = SpatialRelationshipContainer(spatialRelationship: 2, relationshipName:"Overlaps")
        let intersects = SpatialRelationshipContainer(spatialRelationship: 3, relationshipName:"Intersects")
        let crosses = SpatialRelationshipContainer(spatialRelationship: 4, relationshipName:"Crosses")
        let contains = SpatialRelationshipContainer(spatialRelationship: 5, relationshipName:"Contains")
        let disjoint = SpatialRelationshipContainer(spatialRelationship: 6, relationshipName:"Disjoint")
        
        self.spatialRelationships = [within,touches,overlaps,intersects,crosses,contains,disjoint]
        
        self.relationshipTable.delegate = self
        self.relationshipTable.dataSource = self
        self.relationshipTable.scrollEnabled = false
        self.relationshipTable.backgroundColor = UIColor.whiteColor()
        self.relationshipTable.layer.cornerRadius = 5
        self.relationshipTable.layer.borderWidth = 1
        self.relationshipTable.layer.borderColor = UIColor.grayColor().CGColor
        self.relationshipTable.alpha = 0.8
        
        let pointSymbol = AGSSimpleMarkerSymbol()
        pointSymbol.color = UIColor.blueColor()
        
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline = nil
        
        // A composite symbol to symbolize geometries
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(pointSymbol)
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(innerSymbol)
        
        // A renderer for the graphics layer
        let renderer = AGSSimpleRenderer(symbol: compositeSymbol)
        self.graphicsLayer.renderer = renderer
        
        self.userInstructions.text = "Sketch two geometries to see their spatial relationships"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        // Create and add a sketch layer to the map
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        self.mapView.touchDelegate = self.sketchLayer
    }
    
    //MARK: - table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.spatialRelationships.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kCustomCellID = "MyCellID"
        
        // Create a cell
        var cell = tableView.dequeueReusableCellWithIdentifier(kCustomCellID)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: kCustomCellID)
            cell?.textLabel?.textColor = UIColor.blackColor()
        }
        
        // Disable selection
        cell?.selectionStyle = .None
        
        // Get the cell text from the relationship container name
        let relContainer = self.spatialRelationships[indexPath.row] as SpatialRelationshipContainer
        cell?.textLabel?.text = relContainer.name
        
        // If the relationship checked property has been set show a checked box otherwise show an unchecked one
        let image = relContainer.checked ? UIImage(named: "checkbox_full.png") : UIImage(named: "checkbox_empty.png")
        
        // Match the button's size with the image size
        let button = UIButton()
        let frame = CGRectMake(0.0, 0.0, image!.size.width, image!.size.height)
        button.frame = frame
        
        button.setBackgroundImage(image, forState:.Normal)
        
        button.backgroundColor = UIColor.clearColor()
        cell?.accessoryView = button
        cell?.accessoryView?.userInteractionEnabled = false
        
        return cell!
    }
    
    //MARK: - Toolbar actions
    
    @IBAction func add() {
        // Get the sketch layer's geometry and add a new graphic to the graphics layer
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol:nil, attributes:nil)
        
        self.graphicsLayer.addGraphic(graphic)
        
        self.sketchLayer.clear()
        
        // If we exactly two geometries
        if self.graphicsLayer.graphics.count == 2 {
            let geometryEngine = AGSGeometryEngine()
            
            // Get the geometries from the graphicslayer's graphics
            let graphic1 = self.graphicsLayer.graphics[0] as! AGSGraphic
            let graphic2 = self.graphicsLayer.graphics[1] as! AGSGraphic
            
            // If any of the spatial relationships occur set that spatial relationship container's checked property
            if geometryEngine.geometry(graphic1.geometry, withinGeometry: graphic2.geometry) {
                self.spatialRelationships[0].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, touchesGeometry:graphic2.geometry) {
                self.spatialRelationships[1].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, overlapsGeometry:graphic2.geometry) {
                self.spatialRelationships[2].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, intersectsGeometry:graphic2.geometry) {
                self.spatialRelationships[3].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, crossesGeometry:graphic2.geometry) {
                self.spatialRelationships[4].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, containsGeometry:graphic2.geometry) {
                self.spatialRelationships[5].checked = true
            }
            if geometryEngine.geometry(graphic1.geometry, disjointToGeometry:graphic2.geometry) {
                self.spatialRelationships[6].checked = true
            }
            
            // Reload the table
            self.relationshipTable.reloadData()
            
            self.mapView.touchDelegate = nil
            self.geometrySelect.enabled = false
            self.addButton.enabled = false
            
            self.userInstructions.text = "Tap the reset button to start over"
        }
    }
    
    @IBAction func reset() {
        self.mapView.touchDelegate = self.sketchLayer
        self.geometrySelect.enabled = true
        self.addButton.enabled = true
        self.graphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
        
        // Reset the checked property for all spatial relationships
        for var i = 0; i < self.spatialRelationships.count; i++ {
            self.spatialRelationships[i].checked = false
        }
        
        // Reload the table
        self.relationshipTable.reloadData()
        
        self.userInstructions.text = "Sketch two overlapping geometries and add them to the map"
    }
    
    @IBAction func selectGeometry(geomControl:UISegmentedControl) {
        
        // Set the geometry of the sketch layer to match the selected geometry
        switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        case 1:
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        case 2:
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        default:
            break
        }
        
        self.sketchLayer.clear()
    }
}
