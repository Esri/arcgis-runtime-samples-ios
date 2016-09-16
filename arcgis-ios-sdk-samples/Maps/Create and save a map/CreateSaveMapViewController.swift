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

extension UIImage {
    
    func croppedImage(size:CGSize) -> UIImage {
        //calculate rect based on input size
        let originX = (self.size.width - size.width)/2
        let originY = (self.size.height - size.height)/2
        
        let scale = UIScreen.mainScreen().scale
        let rect = CGRect(x: originX*scale, y: originY*scale, width: size.width*scale, height: size.height*scale)
        
        //crop image
        let croppedCGImage = CGImageCreateWithImageInRect(self.CGImage, rect)!
        let croppedImage = UIImage(CGImage: croppedCGImage, scale: scale, orientation: UIImageOrientation.Up)
        
        return croppedImage
    }
}




class CreateSaveMapViewController: UIViewController, CreateOptionsVCDelegate, SaveAsVCDelegate {
    
    let webmapURL = "https://www.arcgis.com/home/webmap/viewer.html?webmap="
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var createOptionsBlurView:UIVisualEffectView!
    @IBOutlet private weak var saveAsBlurView:UIVisualEffectView!
    @IBOutlet private weak var savingToolbar:UIToolbar!
    
    private var createOptionsVC:CreateOptionsViewController!
    private var saveAsVC:SaveAsViewController!
    
    private var portal:AGSPortal!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Auth Manager settings
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "RsFgCI1clPQ7TVwD", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.sharedAuthenticationManager().OAuthConfigurations.addObject(config)
        AGSAuthenticationManager.sharedAuthenticationManager().credentialCache.removeAllCredentials()
        
        let map = AGSMap(basemap: AGSBasemap.imageryBasemap())
        
        self.mapView.map = map
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CreateSaveMapViewController", "CreateOptionsViewController", "SaveAsViewController"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showSuccess() {
        let alertController = UIAlertController(title: "Saved successfully", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { [weak self] (action:UIAlertAction!) -> Void in
            self?.dismissViewControllerAnimated(true, completion: nil)
            })
        
        let openAction = UIAlertAction(title: "Open in Safari", style: UIAlertActionStyle.Default, handler: { [weak self] (action:UIAlertAction!) -> Void in
            if let weakSelf = self {
                UIApplication.sharedApplication().openURL(NSURL(string: "\(weakSelf.webmapURL)\(weakSelf.mapView.map!.item!.itemID)")!)
            }
        })
        
        alertController.addAction(okAction)
        alertController.addAction(openAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: - hide/show create screen
    
    private func toggleCreateView() {
        self.createOptionsBlurView.hidden = !self.createOptionsBlurView.hidden
        
        //reset selection
        if !self.createOptionsBlurView.hidden {
            self.createOptionsVC.resetTableView()
        }
    }
    
    //MARK: - hide/show input screen
    
    private func toggleSaveAsView() {
        self.saveAsBlurView.hidden = !self.saveAsBlurView.hidden
        
        self.view.endEditing(true)
    }
    
    //MARK: - Actions
    
    @IBAction private func newAction() {
        self.toggleCreateView()
    }
    
    @IBAction func saveAsAction(sender: AnyObject) {
        self.portal = AGSPortal(URL: NSURL(string: "https://www.arcgis.com")!, loginRequired: true)
        self.portal.loadWithCompletion { (error) -> Void in
            if let error = error {
                print(error)
            }
            else {
                //get title etc
                self.toggleSaveAsView()
            }
        }
    }
    
    
    @IBAction private func cancelAction() {
        self.view.endEditing(true)
        self.toggleSaveAsView()
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CreateOptionsEmbedSegue" {
            self.createOptionsVC = segue.destinationViewController as! CreateOptionsViewController
            self.createOptionsVC.delegate = self
        }
        else if segue.identifier == "SaveAsEmbedSegue" {
            self.saveAsVC = segue.destinationViewController as! SaveAsViewController
            self.saveAsVC.delegate = self
        }
    }
    
    //MARK: - CreateOptionsVCDelegate
    
    func createOptionsViewController(createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]?) {
        
        //create a map with the selected basemap
        let map = AGSMap(basemap: basemap)
        
        //add the selected operational layers
        if let layers = layers {
            map.operationalLayers.addObjectsFromArray(layers)
        }
        //assign the new map to the map view
        self.mapView.map = map
        
        //hide the create view
        self.toggleCreateView()
    }
    
    //MARK: - SaveAsVCDelegate
    
    func saveAsViewController(saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String?) {
        SVProgressHUD.showWithStatus("Saving", maskType: .Gradient)
        //set the initial viewpoint from map view
        self.mapView.map?.initialViewpoint = self.mapView.currentViewpointWithType(AGSViewpointType.CenterAndScale)
        
        self.mapView.exportImageWithCompletion { [weak self] (image:UIImage?, error:NSError?) -> Void in
            
            if let weakSelf = self {
                //crop the image from the center
                //also to cut on the size
                let croppedImage:UIImage? = image?.croppedImage(CGSize(width: 200, height: 200))
                
                weakSelf.mapView.map?.saveAs(title, portal: weakSelf.portal!, tags: tags, folder: nil, itemDescription: itemDescription, thumbnail: croppedImage, completion: { [weak self] (error) -> Void in
                    
                    //dismiss progress hud
                    SVProgressHUD.dismiss()
                    if let error = error {
                        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
                    }
                    else {
                        self?.showSuccess()
                    }
                    weakSelf.saveAsVC.resetInputFields()
                })
            }
        }
        
        //hide the input screen
        self.toggleSaveAsView()
    }
    
    func saveAsViewControllerDidCancel(saveAsViewController: SaveAsViewController) {
        self.toggleSaveAsView()
    }
}
