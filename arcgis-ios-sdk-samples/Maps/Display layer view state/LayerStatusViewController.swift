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
    @IBOutlet private var mapView: AGSMapView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var visualEffectView: UIVisualEffectView!
    
    private var map: AGSMap!
    
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
        
        //reload table
        self.tableView.reloadData()
        //assign map to the map view
        self.mapView.map = self.map
        //zoom to custom viewpoint
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11e6, y: 45e5, spatialReference: .webMercator()), scale: 5e7))
        
        //layer status logic
        //assign a closure for layerViewStateChangedHandler, in order to receive layer view status changes
        self.mapView.layerViewStateChangedHandler = { [weak self] (layer: AGSLayer, state: AGSLayerViewState) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                //find the index of layer in operational layers list
                //and update its status
                let index = self.map.operationalLayers.index(of: layer)
                if index != NSNotFound {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
        
        //setup source code bar button item
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LayerStatusViewController"]
    }

    //return string for current status name
    func viewStatusString(_ status: AGSLayerViewStatus) -> String {
        var statuses = [String]()
        if status.contains(.active) {
            statuses.append("Active")
        }
        if status.contains(.notVisible) {
            statuses.append("Not Visible")
        }
        if status.contains(.outOfScale) {
            statuses.append("Out of Scale")
        }
        if status.contains(.loading) {
            statuses.append("Loading")
        }
        if status.contains(.error) {
            statuses.append("Error")
        }
        if !statuses.isEmpty {
            return statuses.joined(separator: ", ")
        } else {
            return "Unknown"
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.map?.operationalLayers.count ?? 0
    }
    
    // MARK: - Table view delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerStatusCell", for: indexPath)
        cell.backgroundColor = .clear
        let layer = self.map.operationalLayers[indexPath.row] as! AGSLayer
        
        //if the layer is loaded then show the name
        //else use a template
        if layer.loadStatus == .loaded {
            cell.textLabel?.text = layer.name
        } else {
            cell.textLabel?.text = "Layer \(indexPath.row)"
        }
        
        if let layerViewState = mapView.layerViewState(for: layer) {
            cell.detailTextLabel?.text = viewStatusString(layerViewState.status)
        } else {
            cell.detailTextLabel?.text = "Unknown"
        }
        
        return cell
    }
}
