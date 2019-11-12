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
        //calculate rect based on input size
        let originX = (size.width - size.width) / 2
        let originY = (size.height - size.height) / 2
        
        let scale = UIScreen.main.scale
        let rect = CGRect(x: originX * scale, y: originY * scale, width: size.width * scale, height: size.height * scale)
        
        //crop image
        let croppedCGImage = cgImage!.cropping(to: rect)!
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
        
        return croppedImage
    }
}

class CreateSaveMapViewController: UIViewController, CreateOptionsViewControllerDelegate, SaveAsViewControllerDelegate {
    @IBOutlet private weak var mapView: AGSMapView!
    
    private var portal: AGSPortal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "CreateSaveMapViewController",
            "CreateOptionsViewController",
            "SaveAsViewController"
        ]
        
        //Auth Manager settings
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        // initially show the map creation UI
        performSegue(withIdentifier: "CreateNewSegue", sender: self)
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
        let portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: true)
        self.portal = portal
        portal.load { [weak self] (error) in
            if let error = error {
                print(error)
            } else {
                self?.performSegue(withIdentifier: "SaveAsSegue", sender: self)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let rootController = navController.viewControllers.last {
            if let createOptionsVC = rootController as? CreateOptionsViewController {
                createOptionsVC.delegate = self
            } else if let saveAsVC = rootController as? SaveAsViewController {
                saveAsVC.delegate = self
            }
        }
    }
    
    // MARK: - CreateOptionsViewControllerDelegate
    
    func createOptionsViewController(_ createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]) {
        //create a map with the selected basemap
        let map = AGSMap(basemap: basemap)
        
        //add the selected operational layers
        map.operationalLayers.addObjects(from: layers)
        
        //assign the new map to the map view
        mapView.map = map
        
        createOptionsViewController.dismiss(animated: true)
    }
    
    // MARK: - SaveAsViewControllerDelegate
    
    func saveAsViewController(_ saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String) {
        SVProgressHUD.show(withStatus: "Saving")
        
        //set the initial viewpoint from map view
        mapView.map?.initialViewpoint = mapView.currentViewpoint(with: AGSViewpointType.centerAndScale)
        
        mapView.exportImage { [weak self] (image: UIImage?, error: Error?) in
            guard let self = self else {
                return
            }
            
            //crop the image from the center
            //also to cut on the size
            let croppedImage: UIImage? = image?.croppedImage(CGSize(width: 200, height: 200))
            
            self.mapView.map?.save(as: title, portal: self.portal!, tags: tags, folder: nil, itemDescription: itemDescription, thumbnail: croppedImage, forceSaveToSupportedVersion: true) { [weak self] (error) in
                //dismiss progress hud
                SVProgressHUD.dismiss()
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
