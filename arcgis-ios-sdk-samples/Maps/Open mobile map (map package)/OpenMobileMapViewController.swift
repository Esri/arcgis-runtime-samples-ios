//
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
//

import UIKit
import ArcGIS

class OpenMobileMapViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    private var mapPackage: AGSMobileMapPackage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OpenMobileMapViewController"]
        
        //initialize map package
        self.mapPackage = AGSMobileMapPackage(name: "Yellowstone")
        
        //load map package
        self.mapPackage.load { [weak self] (error: Error?) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let map = self.mapPackage.maps.first {
                //assign the first map from the map package to the map view
                self.mapView.map = map
            } else {
                self.presentAlert(message: "No mobile maps found in the map package")
            }
        }
    }
}
