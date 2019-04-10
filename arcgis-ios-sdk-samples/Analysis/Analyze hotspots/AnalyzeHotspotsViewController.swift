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
    
    /// Geoprocessing task with the url of the service
    private let geoprocessingTask = AGSGeoprocessingTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/911CallsHotspot/GPServer/911%20Calls%20Hotspot")!)
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    private var geoprocessingJob: AGSGeoprocessingJob?
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "AnalyzeHotspotsViewController",
            "HotspotSettingsViewController"
        ]

        //initialize map with basemap
        let map = AGSMap(basemap: .topographic())
        
        //center for initial viewpoint
        let center = AGSPoint(x: -13671170.647485, y: 5693633.356735, spatialReference: .webMercator())
        
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: center, scale: 57779)
        
        //assign map to map view
        mapView.map = map
    }
    
    private func analyzeHotspots(_ fromDate: Date, toDate: Date) {
        //cancel previous job request
        self.geoprocessingJob?.progress.cancel()
        
        let fromDateString = dateFormatter.string(from: fromDate)
        let toDateString = dateFormatter.string(from: toDate)
        
        //parameters
        let params = AGSGeoprocessingParameters(executionType: .asynchronousSubmit)
        params.processSpatialReference = self.mapView.map?.spatialReference
        params.outputSpatialReference = self.mapView.map?.spatialReference
        
        //query string
        let queryString = "(\"DATE\" > date '\(fromDateString) 00:00:00' AND \"DATE\" < date '\(toDateString) 00:00:00')"
        params.inputs["Query"] = AGSGeoprocessingString(value: queryString)
        
        //job
        let geoprocessingJob = geoprocessingTask.geoprocessingJob(with: params)
        self.geoprocessingJob = geoprocessingJob
        
        //start job
        geoprocessingJob.start(statusHandler: { (status: AGSJobStatus) in
            //show progress hud with job status
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (result: AGSGeoprocessingResult?, error: Error?) in
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                //show error
                self.presentAlert(error: error)
            } else {
                //a map image layer is generated as a result
                //remove any layer previously added to the map
                self.mapView.map?.operationalLayers.removeAllObjects()
                
                //add the new layer to the map
                self.mapView.map?.operationalLayers.add(result!.mapImageLayer!)
                
                //set map view's viewpoint to the new layer's full extent
                (self.mapView.map?.operationalLayers.firstObject as! AGSLayer).load { (error: Error?) in
                    if error == nil {
                        //set viewpoint as the extent of the mapImageLayer
                        if let extent = result?.mapImageLayer?.fullExtent {
                            self.mapView.setViewpointGeometry(extent, completion: nil)
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - HotspotSettingsVCDelegate
    
    func hotspotSettingsViewController(_ hotspotSettingsViewController: HotspotSettingsViewController, didSelectDates fromDate: Date, toDate: Date) {
        hotspotSettingsViewController.dismiss(animated: true)
        
        analyzeHotspots(fromDate, toDate: toDate)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? HotspotSettingsViewController {
            controller.delegate = self
        }
    }
}
