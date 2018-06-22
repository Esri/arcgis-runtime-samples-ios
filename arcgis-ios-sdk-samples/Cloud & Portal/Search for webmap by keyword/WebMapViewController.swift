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
//

import UIKit
import ArcGIS

class WebMapViewController: UIViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    var portalItem:AGSPortalItem!
    var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize map with selected portal item
        self.map = AGSMap(item: portalItem)
        
        AGSAuthenticationManager.shared().delegate = self
        
        self.title = self.map.item?.title
        
        //assign map to the map view
        self.mapView.map = self.map
    }

    
    //MARK: - AGSAuthenticationManagerDelegate
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        SVProgressHUD.showError(withStatus: "Web map access denied")
        challenge.cancel()
        _ = self.navigationController?.popViewController(animated: true)
    }
}
