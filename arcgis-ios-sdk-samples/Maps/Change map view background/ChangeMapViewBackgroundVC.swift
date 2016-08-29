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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ChangeMapViewBackgroundVC", "GridSettingsViewController"]
        
        //initialize map with just spatial reference
        //in order for background grid to be visible
        let map = AGSMap(spatialReference: AGSSpatialReference.webMercator())
        
        //assign map to the map view
        self.mapView.map = map
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - GridSettingsVCDelegate
    
    func gridSettingsViewController(gridSettingsViewController: GridSettingsViewController, didUpdateBackgroundGrid grid: AGSBackgroundGrid) {
        
        //update background grid on the map view
        self.mapView.backgroundGrid = grid
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "EmbedSegue" {
            let controller = segue.destinationViewController as! GridSettingsViewController
            controller.delegate = self
        }
    }
}
