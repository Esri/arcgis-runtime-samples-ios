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

class WebMapViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    var portalItem:AGSPortalItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let portalItem = portalItem else {
            return
        }
        
        // register to be notified about authentication challenges
        AGSAuthenticationManager.shared().delegate = self

        // initialize a map with the portal item
        let map = AGSMap(item: portalItem)
        // assign the map to the map view
        mapView.map = map
        
        title = portalItem.title
    }
}

extension WebMapViewController: AGSAuthenticationManagerDelegate {
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        
        // if a challenge is received, then the portal item is not fully public and cannot be displayed
        
        // stop attempts at map loading
        mapView.map = nil
        
        // don't present this challenge
        challenge.cancel()
        
        // close this view controller
        navigationController?.popViewController(animated: true)
        
        // notify the user
        SVProgressHUD.showError(withStatus: "Web map access denied")
    }
    
}
