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
    
    private var portal: AGSPortal!
    private var portalItem: AGSPortalItem!
    private var scene: AGSScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OpenSceneViewController"]

        //initialize portal with AGOL
        portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        //get the portal item
        let portalItem = AGSPortalItem.init(portal: portal, itemID: "a13c3c3540144967bc933cb5e498b8e4")
        
        //create scene from portal item
        let scene = AGSScene(item: portalItem)
        
        sceneView.scene = scene
    }
}
