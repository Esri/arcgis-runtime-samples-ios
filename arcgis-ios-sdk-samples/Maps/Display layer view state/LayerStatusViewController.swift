// Copyright 2015 Esri.
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

class LayerStatusViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var tableView:UITableView!
    
    private var map:AGSMap!
    
    private var viewStatusArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.map = AGSMap()
        
        //create tiled layer using a url
        let tiledLayer = AGSArcGISTiledLayer(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer")!)
        //add the layer to the map
        self.map.operationalLayers.addObject(tiledLayer)

        //create an map image layer using a url
        let imageLayer = AGSArcGISMapImageLayer(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        imageLayer.minScale = 40000000
        imageLayer.maxScale = 2000000
        //add it to the map
        self.map.operationalLayers.addObject(imageLayer)
        
        //create feature layer using a url
        let featureTable = AGSServiceFeatureTable(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0"))
        let featurelayer = AGSFeatureLayer(featureTable: featureTable)
        //add it to the map
        self.map.operationalLayers.addObject(featurelayer)
        
        //initialize the view status array to `Unknown`
        self.populateViewStatusArray()
        //reload table
        self.tableView.reloadData()
        //assign map to the map view
        self.mapView.map = self.map
        //zoom to custom viewpoint
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11e6, y: 45e5, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 5e7))
        
        //layer status logic
        //assign a closure for layerViewStateChangedHandler, in order to receive layer view status changes
        self.mapView.layerViewStateChangedHandler = { [weak self] (layer:AGSLayer, state:AGSLayerViewState) in
            if let weakSelf = self {
                //find the index of layer in operational layers list
                //and update its status
                let index = weakSelf.map.operationalLayers.indexOfObject(layer)
                if index != NSNotFound {
                    weakSelf.viewStatusArray[index] = weakSelf.viewStatusString(state.status)
                    
                    self?.tableView.reloadData()
                }
            }
        }
        
        //setup source code bar button item
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LayerStatusViewController"]

    }
    
    //initialize status array to `Unknown`
    func populateViewStatusArray() {
        for i in 0...self.map.operationalLayers.count-1 {
            self.viewStatusArray.append("Unknown")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //return string for current status name
    func viewStatusString(status: AGSLayerViewStatus) -> String {
        switch status {
        case .Active:
            return "Active"
        case .NotVisible:
            return "Not Visible"
        case .OutOfScale:
            return "Out of Scale"
        case .Loading:
            return "Loading"
        case .Error:
            return "Error"
        default:
            return "Unknown"
        }
    }
    
    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.map?.operationalLayers.count ?? 0
    }
    
    //MARK: - Table view delegates
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LayerStatusCell")!
        cell.backgroundColor = UIColor.clearColor()
        let layer = self.map.operationalLayers[UInt(indexPath.row)] as! AGSLayer
        
        cell.textLabel?.text = layer.name ?? "Layer \(indexPath.row)"
        cell.detailTextLabel?.text = self.viewStatusArray[indexPath.row]
        
        return cell
    }
    
    
}
