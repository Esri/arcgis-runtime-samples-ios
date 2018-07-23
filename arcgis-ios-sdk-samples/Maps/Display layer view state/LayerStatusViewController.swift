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
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var tableView:UITableView!
    @IBOutlet private var visualEffectView:UIVisualEffectView!
    
    private var map:AGSMap!
    
    private var viewStatusArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //constraint visual effect view to the map view's attribution label
        let constraint = self.visualEffectView.bottomAnchor.constraint(equalTo: self.mapView.attributionTopAnchor, constant: -10)
        
        //activate constraint
        constraint.isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.map = AGSMap()
        
        //create tiled layer using a url
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer")!)
        //add the layer to the map
        self.map.operationalLayers.add(tiledLayer)

        //create an map image layer using a url
        let imageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        imageLayer.minScale = 40000000
        imageLayer.maxScale = 2000000
        //add it to the map
        self.map.operationalLayers.add(imageLayer)
        
        //create feature layer using a url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0")!)
        let featurelayer = AGSFeatureLayer(featureTable: featureTable)
        //add it to the map
        self.map.operationalLayers.add(featurelayer)
        
        //initialize the view status array to `Unknown`
        self.populateViewStatusArray()
        //reload table
        self.tableView.reloadData()
        //assign map to the map view
        self.mapView.map = self.map
        //zoom to custom viewpoint
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11e6, y: 45e5, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 5e7))
        
        //layer status logic
        //assign a closure for layerViewStateChangedHandler, in order to receive layer view status changes
        self.mapView.layerViewStateChangedHandler = { [weak self] (layer:AGSLayer, state:AGSLayerViewState) in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                //find the index of layer in operational layers list
                //and update its status
                let index = strongSelf.map.operationalLayers.index(of: layer)
                if index != NSNotFound {
                    strongSelf.viewStatusArray[index] = strongSelf.viewStatusString(state.status)
                    
                    strongSelf.tableView.reloadData()
                }
            }
        }
        
        //setup source code bar button item
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LayerStatusViewController"]

    }
    
    //initialize status array to `Unknown`
    func populateViewStatusArray() {
        for _ in 0...self.map.operationalLayers.count-1 {
            self.viewStatusArray.append("Unknown")
        }
    }

    //return string for current status name
    func viewStatusString(_ status: AGSLayerViewStatus) -> String {
        switch status {
        case AGSLayerViewStatus.active:
            return "Active"
        case AGSLayerViewStatus.notVisible:
            return "Not Visible"
        case AGSLayerViewStatus.outOfScale:
            return "Out of Scale"
        case AGSLayerViewStatus.loading:
            return "Loading"
        case AGSLayerViewStatus.error:
            return "Error"
        default:
            return "Unknown"
        }
    }
    
    //MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.map?.operationalLayers.count ?? 0
    }
    
    //MARK: - Table view delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerStatusCell", for: indexPath)
        cell.backgroundColor = .clear
        let layer = self.map.operationalLayers[indexPath.row] as! AGSLayer
        
        //if the layer is loaded then show the name
        //else use a template
        if layer.loadStatus == .loaded {
            cell.textLabel?.text = layer.name
        }
        else {
            cell.textLabel?.text = "Layer \(indexPath.row)"
        }
        
        cell.detailTextLabel?.text = self.viewStatusArray[indexPath.row]
        
        return cell
    }
}
