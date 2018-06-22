// Copyright 2017 Esri.
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

class AnalyzeHotspotsViewController: UIViewController, HotspotSettingsVCDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var containerView: UIView!
    
    
    private var geoprocessingTask: AGSGeoprocessingTask!
    private var geoprocessingJob: AGSGeoprocessingJob!
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["AnalyzeHotspotsViewController", "HotspotSettingsViewController"]

        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //center for initial viewpoint
        let center = AGSPoint(x: -13671170.647485, y: 5693633.356735, spatialReference: AGSSpatialReference(wkid: 3857))
        
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: center, scale: 57779)
        
        //assign map to map view
        self.mapView.map = map
        
        //initilaize geoprocessing task with the url of the service
        self.geoprocessingTask = AGSGeoprocessingTask(url: URL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/911CallsHotspot/GPServer/911%20Calls%20Hotspot")!)
    }
    
    private func analyzeHotspots(_ fromDate: String, toDate: String) {
        
        //cancel previous job request
        self.geoprocessingJob?.progress.cancel()
        
        //parameters
        let params = AGSGeoprocessingParameters(executionType: .asynchronousSubmit)
        params.processSpatialReference = self.mapView.map?.spatialReference
        params.outputSpatialReference = self.mapView.map?.spatialReference
        
        //query string
        let queryString = "(\"DATE\" > date '\(fromDate) 00:00:00' AND \"DATE\" < date '\(toDate) 00:00:00')"
        params.inputs["Query"] = AGSGeoprocessingString(value: queryString)
        
        //job
        self.geoprocessingJob = self.geoprocessingTask.geoprocessingJob(with: params)
        
        //start job
        self.geoprocessingJob.start(statusHandler: { (status: AGSJobStatus) in
            //show progress hud with job status
            SVProgressHUD.show(withStatus: status.statusString())
            
        }) { [weak self] (result: AGSGeoprocessingResult?, error: Error?) in
            if let error = error {
                //show error
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //a map image layer is generated as a result
                //remove any layer previously added to the map
                self?.mapView.map?.operationalLayers.removeAllObjects()
                
                //add the new layer to the map
                self?.mapView.map?.operationalLayers.add(result!.mapImageLayer!)
                
                //set map view's viewpoint to the new layer's full extent
                (self?.mapView.map?.operationalLayers.firstObject as! AGSLayer).load { (error: Error?) in
                    if error == nil {
                        
                        //set viewpoint as the extent of the mapImageLayer
                        if let extent = result?.mapImageLayer?.fullExtent {
                            self?.mapView.setViewpointGeometry(extent, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - HotspotSettingsVCDelegate
    
    func hotspotSettingsViewController(_ hotspotSettingsViewController: HotspotSettingsViewController, didSelectDates fromDate: String, toDate: String) {
        
        self.analyzeHotspots(fromDate, toDate: toDate)
        self.toggleSettingsView(on: false)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SettingsSegue" {
            let controller = segue.destination as! HotspotSettingsViewController
            controller.delegate = self
        }
    }
    
    //MARK: - Toggle settings view
    
    private func toggleSettingsView(on: Bool) {
        self.containerView.isHidden = !on
    }
    
    //MARK: - Actions
    
    @IBAction func changeDatesAction() {
        self.toggleSettingsView(on: true)
    }
}
