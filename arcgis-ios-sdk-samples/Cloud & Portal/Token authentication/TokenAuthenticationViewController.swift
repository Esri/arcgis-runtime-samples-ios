//
// Copyright © 2019 Esri.
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

class TokenAuthenticationViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
        let portalItem = AGSPortalItem(portal: portal, itemID: "e5039444ef3c48b8a8fdc9227f9be7c1")
        return AGSMap(item: portalItem)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "TokenAuthenticationViewController"
        ]
    }
}
