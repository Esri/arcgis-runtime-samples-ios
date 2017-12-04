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



class CustomCalloutPopUpViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var lblName: UILabel!
    private var map:AGSMap!
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create popup map view
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        //assign map to the map view
        self.mapView.map = self.map
      }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}
