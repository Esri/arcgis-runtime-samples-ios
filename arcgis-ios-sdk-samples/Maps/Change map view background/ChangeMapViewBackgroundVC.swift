// Copyright 2016 Esri.
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

class ChangeMapViewBackgroundVC: UIViewController, GridSettingsVCDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var settingsContainerView: UIView!
    
    private var gridSettingsViewController:GridSettingsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ChangeMapViewBackgroundVC", "GridSettingsViewController"]
        
        //initialize tiled layer
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer")!)

        //initialize map with tiled layer as basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
        
        //set initial viewpoint
        let center = AGSPoint(x: 3224786.498918, y: 2661231.326777, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: center, scale: 236663484.12225574)
        
        //assign map to the map view
        self.mapView.map = map
    }
    
    //MARK: - GridSettingsVCDelegate
    
    func gridSettingsViewController(_ gridSettingsViewController: GridSettingsViewController, didUpdateBackgroundGrid grid: AGSBackgroundGrid) {
        
        //update background grid on the map view
        self.mapView.backgroundGrid = grid
    }
    
    func gridSettingsViewControllerWantsToClose(_ gridSettingsViewController: GridSettingsViewController) {
        self.settingsContainerView.isHidden = true
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "EmbedSegue" {
            self.gridSettingsViewController = segue.destination as? GridSettingsViewController
            self.gridSettingsViewController.delegate = self
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func changeBackgroundAction() {
        //default color
        self.gridSettingsViewController.colorButton.backgroundColor = self.mapView.backgroundGrid?.color
        self.gridSettingsViewController.lineColorButton.backgroundColor = self.mapView.backgroundGrid?.gridLineColor
        
        self.settingsContainerView.isHidden = false
    }
}
