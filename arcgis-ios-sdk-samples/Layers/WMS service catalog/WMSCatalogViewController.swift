// Copyright 2018 Esri.
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

class WMSCatalogViewController: UIViewController, UITableViewDataSource {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var map: AGSMap!
    private var allLayers = [AGSWMSLayer]()
    private var wmsService: AGSWMSService!
    
    private let WMS_SERVICE_URL = URL(string: "https://idpgis.ncep.noaa.gov/arcgis/services/NWS_Forecasts_Guidance_Warnings/natl_fcst_wx_chart/MapServer/WMSServer?request=GetCapabilities&service=WMS")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["WMSCatalogViewController"]
        
        // initialize the map with dark gray canvase basemap
        map = AGSMap(basemap: AGSBasemap.darkGrayCanvasVector())
        
        // assign the map to the map view
        mapView.map = map
        
        // zoom to custom viewpoint
        let viewPoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -16390242.238100, yMin: 1229349.831800, xMax: -5413415.367700, yMax: 8519715.614400, spatialReference: AGSSpatialReference.webMercator()))
        self.mapView.setViewpoint(viewPoint)
        
        // initialize the WMS service with the service URL
        wmsService = AGSWMSService(url: WMS_SERVICE_URL)
        
        // load the WMS service
        wmsService.load {[weak self] (error) in
            guard error == nil else {
                SVProgressHUD.showError(withStatus: "Error loading WMS service: \(error!.localizedDescription)", maskType: .gradient)
                return
            }
            
            // get the service info (metadata) from the service
            let wmsServiceInfo = self?.wmsService.serviceInfo
            
            // get the list of layer infos from the service info
            let layerInfos = wmsServiceInfo?.layerInfos as! [AGSWMSLayerInfo]
            
            self?.createLayers(using: layerInfos)
        }
    }
    
    // MARK: - Helper methods
    
    func createLayers(using layerInfos: [AGSWMSLayerInfo]) {
        for info in layerInfos {
            for subL in info.sublayerInfos as! [AGSWMSLayerInfo] {
                // initialize the WMS layer with the layer info of the top-most layer
                let wmsLayer = AGSWMSLayer(layerInfos: [subL])
                // populate array
                allLayers.append(wmsLayer)
            }
        }
        // reload table view
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allLayers.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Operational layers"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerNameCell")!
        cell.backgroundColor = UIColor.clear

        let wmsLayer = allLayers[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = wmsLayer.name

        // accessory switch
        let visibilitySwitch = UISwitch(frame: CGRect.zero)
        visibilitySwitch.tag = (indexPath as NSIndexPath).row
        visibilitySwitch.isOn = false
        visibilitySwitch.addTarget(self, action: #selector(WMSCatalogViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        cell.accessoryView = visibilitySwitch
        
        return cell
    }
    
    // MARK: - Actions
    
    func switchChanged(_ sender:UISwitch) {
        let index = sender.tag
        
        let wmsLayer = allLayers[index]
        wmsLayer.isVisible = sender.isOn
        
        // add or remove layer
        (wmsLayer.isVisible) ? map.operationalLayers.add(wmsLayer) : map.operationalLayers.remove(wmsLayer)
    }

}
