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

import UIKit
import ArcGIS

private extension UIImage {
    func croppedImage(_ size: CGSize) -> UIImage {
        // Calculate rect based on input size.
        let originX = (size.width - size.width) / 2
        let originY = (size.height - size.height) / 2
        
        let scale = UIScreen.main.scale
        let rect = CGRect(x: originX * scale, y: originY * scale, width: size.width * scale, height: size.height * scale)
        
        // Crop image.
        let croppedCGImage = cgImage!.cropping(to: rect)!
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
        
        return croppedImage
    }
}

class CreateSaveMapViewController: UIViewController, CreateOptionsViewControllerDelegate, SaveAsViewControllerDelegate {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var newMapButton: UIBarButtonItem!
    
    let apiKey = AGSArcGISRuntimeEnvironment.apiKey
    let oAuthConfiguration: AGSOAuthConfiguration
    var portalFolders = [AGSPortalFolder]()
    private let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
    
    required init?(coder aDecoder: NSCoder) {
        // Auth Manager settings
        oAuthConfiguration = AGSOAuthConfiguration(portalURL: nil, clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oAuthConfiguration)
        
        // Temporarily unset the API key for this sample.
        // Please see the additional information in the README.
        AGSArcGISRuntimeEnvironment.apiKey = ""
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "CreateSaveMapViewController",
            "CreateOptionsViewController",
            "SaveAsViewController"
        ]
        portal.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Get the user's array of portal folders.
                self.portal.user?.fetchContent { _, folders, _ in
                    if let portalFolders = folders {
                        self.portalFolders = portalFolders
                    }
                }
                // Initially show the map creation UI.
                self.performSegue(withIdentifier: "CreateNewSegue", sender: self)
                self.newMapButton.isEnabled = true
                self.saveButton.isEnabled = true
            }
        }
    }
    
    deinit {
        // Reset the API key after successful login.
        AGSArcGISRuntimeEnvironment.apiKey = apiKey
        AGSAuthenticationManager.shared().oAuthConfigurations.remove(oAuthConfiguration)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
    }
    
    private func showSuccess() {
        let alertController = UIAlertController(title: "Saved Successfully", message: nil, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        
        let openAction = UIAlertAction(title: "Open In Safari", style: .default) { _ in
            if let itemID = self.mapView.map?.item?.itemID,
               var components = URLComponents(string: "https://www.arcgis.com/home/webmap/viewer.html") {
                components.queryItems = [URLQueryItem(name: "webmap", value: itemID)]
                UIApplication.shared.open(components.url!, options: [:])
            }
        }
        
        alertController.addAction(okAction)
        alertController.addAction(openAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func saveAsAction(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "SaveAsSegue", sender: self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
           let rootController = navController.viewControllers.last {
            if let createOptionsViewController = rootController as? CreateOptionsViewController {
                createOptionsViewController.delegate = self
            } else if let saveAsViewController = rootController as? SaveAsViewController {
                saveAsViewController.delegate = self
                saveAsViewController.portalFolders = portalFolders
            }
        }
    }
    
    // MARK: - CreateOptionsViewControllerDelegate
    
    func createOptionsViewController(_ createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]) {
        // Create a map with the selected basemap.
        let map = AGSMap(basemap: basemap)
        
        // Add the selected operational layers.
        map.operationalLayers.addObjects(from: layers)
        
        // Assign the new map to the map view.
        mapView.map = map
        
        createOptionsViewController.dismiss(animated: true)
    }
    
    // MARK: - SaveAsViewControllerDelegate
    
    func saveAsViewController(_ saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String, folder: AGSPortalFolder?) {
        UIApplication.shared.showProgressHUD(message: "Saving")
        
        // Set the initial viewpoint from map view.
        mapView.map?.initialViewpoint = mapView.currentViewpoint(with: AGSViewpointType.centerAndScale)
        
        mapView.exportImage { [weak self] (image: UIImage?, error: Error?) in
            guard let self = self else {
                return
            }
            
            // Crop the image from the center.
            // Also to cut on the size.
            let croppedImage: UIImage? = image?.croppedImage(CGSize(width: 200, height: 200))
            
            self.mapView.map?.save(as: title, portal: self.portal, tags: tags, folder: folder, itemDescription: itemDescription, thumbnail: croppedImage, forceSaveToSupportedVersion: true) { [weak self] (error) in
                // Dismiss progress hud.
                UIApplication.shared.hideProgressHUD()
                if let error = error {
                    saveAsViewController.presentAlert(error: error)
                } else {
                    saveAsViewController.dismiss(animated: true) {
                        self?.showSuccess()
                    }
                }
            }
        }
    }
}
