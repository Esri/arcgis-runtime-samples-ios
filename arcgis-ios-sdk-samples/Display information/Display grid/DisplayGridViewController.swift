//
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

class DisplayGridViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    private var gridSettingsViewController:DisplayGridSettingsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayGridViewController", "DisplayGridSettingsViewController"]

        // Initialize map with imagery basemap
        let map = AGSMap(basemap: AGSBasemap.imagery())
        
        // Set initial viewpoint
        let center = AGSPoint(x: -7702852.905619, y: 6217972.345771, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: center, scale: 23227)
        
        // Assign map to the map view
        mapView.map = map
        
        // Add lat long grid
        mapView.grid = AGSLatitudeLongitudeGrid()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        //
        // For popover or non modal presentation
        return UIModalPresentationStyle.none
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayGridSettingsSegue" {
            //
            // Set grid settings view controller
            gridSettingsViewController = segue.destination as! DisplayGridSettingsViewController
            gridSettingsViewController.mapView = self.mapView

            // Pop over settings
            gridSettingsViewController.presentationController?.delegate = self
            gridSettingsViewController.popoverPresentationController?.passthroughViews = [self.mapView]
            
            // Preferred content size
            if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
                gridSettingsViewController.preferredContentSize = CGSize(width: 375, height: 350)
            }
            else {
                gridSettingsViewController.preferredContentSize = CGSize(width: 375, height: 250)
            }
        }
    }
}
