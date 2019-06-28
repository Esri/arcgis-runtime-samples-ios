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
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let mobileScenePackageURL = Bundle.main.url(forResource: "philadelphia", withExtension: "mspk") else {
            assertionFailure("Could not find mobile scene package")
            return
        }
        
        AGSMobileScenePackage.checkDirectReadSupportForMobileScenePackage(atFileURL: mobileScenePackageURL) { [weak self] (isDirectReadSupported, error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if isDirectReadSupported {
                self.mobileScenePackage = AGSMobileScenePackage(fileURL: mobileScenePackageURL)
            } else if let temporaryURL = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: mobileScenePackageURL, create: true) {
                let unpackedURL = temporaryURL.appendingPathComponent((mobileScenePackageURL.lastPathComponent as NSString).deletingPathExtension, isDirectory: true)
                AGSMobileScenePackage.unpack(atFileURL: mobileScenePackageURL, outputDirectory: unpackedURL, completion: { [weak self] (error) in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        self.mobileScenePackage = AGSMobileScenePackage(fileURL: unpackedURL)
                    }
                })
            }
        }
    }
    
    /// The mobile scene package used by the view controller.
    var mobileScenePackage: AGSMobileScenePackage! {
        didSet {
            mobileScenePackage?.load { [weak self] _ in
                self?.mobileScenePackageDidLoad()
            }
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
