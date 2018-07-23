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

class MapViewScreenshotViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var overlayParentView:UIView!
    @IBOutlet private weak var overlayImageView:UIImageView!
    
    var map:AGSMap!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    
    var shutterSound:SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapViewScreenshotViewController"]
        
        //instantiate map with imagegry basemap
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //initialize and assign tap gesture to hide overlay parent view
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MapViewScreenshotViewController.hideOverlayParentView))
        self.overlayParentView.addGestureRecognizer(self.tapGestureRecognizer)
        
        //add border to the overlay image view
        self.overlayImageView.layer.borderColor = UIColor.white.cgColor
        self.overlayImageView.layer.borderWidth = 2
    }
    
    //MARK: - Actions
    
    //hide the screenshot overlay view
    @objc func hideOverlayParentView() {
        self.overlayParentView.isHidden = true
    }
    
    //show the screenshot overlay view
    private func showOverlayParentView() {
        self.overlayParentView.isHidden = false
    }
    
    //called when the user taps on the screenshot button
    @IBAction private func screenshotAction(_ sender: AnyObject) {
        //hide the screenshot view if currently visible
        self.hideOverlayParentView()
        
        //the method on map view we can use to get the screenshot image
        self.mapView.exportImage { [weak self] (image:UIImage?, error:Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            if let image = image {
                //on completion imitate flash
                self?.imitateFlashAndPreviewImage(image)
            }
        }
    }
    
    //imitate the white flash screen when the user taps on the screenshot button
    private func imitateFlashAndPreviewImage(_ image:UIImage) {
        
        let flashView = UIView(frame: self.mapView.bounds)
        flashView.backgroundColor = .white
        self.mapView.addSubview(flashView)
        
        //animate the white flash view on and off to show the flash effect
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            flashView.alpha = 0
        }, completion: { [weak self] (finished) -> Void in
            //On completion play the shutter sound
            self?.playShutterSound()
            flashView.removeFromSuperview()
            //show the screenshot on screen
            self?.overlayImageView.image = image
            self?.showOverlayParentView()
        })
    }
    
    //to play the shutter sound once the screenshot is taken
    func playShutterSound() {
        if self.shutterSound == 0 {
            if let filepath = Bundle.main.path(forResource: "Camera Shutter", ofType: "caf") {
                let url = URL(fileURLWithPath: filepath)
                AudioServicesCreateSystemSoundID(url as CFURL, &self.shutterSound)
            }
        }
        
        AudioServicesPlaySystemSound(self.shutterSound)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(self.shutterSound)
    }
}
