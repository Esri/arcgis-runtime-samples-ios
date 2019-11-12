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

/// A view controller that manages the interface of the Open Mobile Scene (Scene
/// Package) sample.
class OpenMobileSceneViewController: UIViewController {
    /// The mobile scene package used by the view controller.
    let mobileScenePackage: AGSMobileScenePackage = {
        let mobileScenePackageURL = Bundle.main.url(forResource: "philadelphia", withExtension: "mspk")!
        return AGSMobileScenePackage(fileURL: mobileScenePackageURL)
    }()
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        mobileScenePackage.load { [weak self] _ in
            self?.mobileScenePackageDidLoad()
        }
    }
    
    /// Called in response to the mobile scene package load operation
    /// completing.
    func mobileScenePackageDidLoad() {
        loadViewIfNeeded()
        if let error = mobileScenePackage.loadError {
            presentAlert(error: error)
        } else {
            sceneView.scene = mobileScenePackage.scenes.first
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["OpenMobileSceneViewController"]
    }
}
