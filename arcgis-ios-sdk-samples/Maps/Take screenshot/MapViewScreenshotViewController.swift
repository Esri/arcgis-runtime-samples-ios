// Copyright 2015 Esri.
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
        self.map = AGSMap(basemap: AGSBasemap.imageryBasemap())
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //initialize and assign tap gesture to hide overlay parent view
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideOverlayParentView")
        self.overlayParentView.addGestureRecognizer(self.tapGestureRecognizer)
        
        //add border to the overlay image view
        self.overlayImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.overlayImageView.layer.borderWidth = 2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    //hide the screenshot overlay view
    func hideOverlayParentView() {
        self.overlayParentView.hidden = true
    }
    
    //show the screenshot overlay view
    private func showOverlayParentView() {
        self.overlayParentView.hidden = false
    }
    
    //called when the user taps on the screenshot button
    @IBAction private func screenshotAction(sender: AnyObject) {
        //hide the screenshot view if currently visible
        self.hideOverlayParentView()
        
        //the method on map view we can use to get the screenshot image
        self.mapView.exportImageWithCompletion { [weak self] (image:UIImage?, error:NSError?) -> Void in
            if let error = error {
                UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
            }
            if let image = image {
                //on completion imitate flash
                self?.imitateFlash(image)
            }
        }
    }
    
    //imitate the white flash screen when the user taps on the screenshot button
    private func imitateFlash(image:UIImage) {
        let flashView = UIView(frame: self.mapView.bounds)
        flashView.backgroundColor = UIColor.whiteColor()
        self.mapView.addSubview(flashView)
        //animate the white flash view on and off to show the flash effect
        UIView.animateWithDuration(0.3, animations: { [weak self] () -> Void in
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
            if let filepath = NSBundle.mainBundle().pathForResource("Camera Shutter", ofType: "caf") {
                if let url = NSURL(fileURLWithPath: filepath) {
                    AudioServicesCreateSystemSoundID(url, &self.shutterSound)
                }
            }
        }
        
        AudioServicesPlaySystemSound(self.shutterSound)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(self.shutterSound)
    }
}
