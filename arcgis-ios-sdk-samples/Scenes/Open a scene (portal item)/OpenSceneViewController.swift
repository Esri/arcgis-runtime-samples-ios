// Copyright 2018 Esri.
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

class OpenSceneViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["OpenSceneViewController"]

        // Initialize portal with AGOL.
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        // Get the portal item, a scene features Berlin, Germany.
        let portalItem = AGSPortalItem(portal: portal, itemID: "31874da8a16d45bfbc1273422f772270")
        
        // Create scene from the portal item.
        let scene = AGSScene(item: portalItem)
        
        // Assign the scene to the scene view.
        sceneView.scene = scene
    }
}
