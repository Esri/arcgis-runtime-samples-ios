// Copyright 2019 Esri.
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

class ViewContentBeneathTerrainSurfaceViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
        }
    }
    
    /// Creates a scene with a portal item.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        //initialize portal with AGOL
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        //get the portal item
        let portalItem = AGSPortalItem(portal: portal, itemID: "91a4fafd747a47c7bab7797066cb9272")
        
        let scene = AGSScene(item: portalItem)
        
        // changing the navigation constraint manually
        scene.baseSurface?.navigationConstraint = .none
        scene.baseSurface?.opacity = 0.6
        
        return scene
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ViewContentBeneathTerrainSurfaceViewController"]
    }
}
