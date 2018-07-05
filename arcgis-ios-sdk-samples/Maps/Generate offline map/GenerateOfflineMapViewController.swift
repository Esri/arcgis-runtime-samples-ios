//
// Copyright 2017 Esri.
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

class GenerateOfflineMapViewController: UIViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var extentView:UIView!
    @IBOutlet var barButtonItem:UIBarButtonItem!
    @IBOutlet var progressView:UIProgressView!
    @IBOutlet var progressLabel:UILabel!
    @IBOutlet var progressParentView:UIView!
    @IBOutlet var cancelButton:UIButton!
    
    private var portalItem:AGSPortalItem!
    private var parameters:AGSGenerateOfflineMapParameters!
    private var offlineMapTask:AGSOfflineMapTask!
    private var generateOfflineMapJob:AGSGenerateOfflineMapJob!
    private var shouldShowAlert = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateOfflineMapViewController"]

        //Auth Manager settings
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.shouldShowAlert {
            
            self.shouldShowAlert = false
            self.showAlert()
        }
    }
    
    private func addMap() {
        
        //portal for the web map
        let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
        
        //portal item for web map
        self.portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        
        //map from portal item
        let map = AGSMap(item: self.portalItem)
        
        //assign map to the map view
        self.mapView.map = map
        
        //disable the bar button item until the map loads
        self.mapView.map?.load { [weak self] (error) in
            
            guard error == nil else {
                
                //show error
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
                return
            }
            
            self?.title = self?.mapView.map?.item?.title
            self?.barButtonItem.isEnabled = true
        }
        
        //instantiate offline map task
        self.offlineMapTask = AGSOfflineMapTask(portalItem: self.portalItem)
        
        //setup extent view
        self.extentView.layer.borderColor = UIColor.red.cgColor
        self.extentView.layer.borderWidth = 3
    }
    
    private func defaultParameters() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Getting default parameters")
        
        //default parameters for offline map task
        self.offlineMapTask.defaultGenerateOfflineMapParameters(withAreaOfInterest: self.frameToExtent()) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            guard error == nil else {
                
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
                return
            }
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let parameters = parameters else {
                return
            }
            
            //will need the parameters for creating the job later
            self?.parameters = parameters
            
            //take map offline
            self?.takeMapOffline()
        }
    }
    
    private func takeMapOffline() {
        
        //create a unique name for the geodatabase based on current timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fullPath = "\(path)/\(dateFormatter.string(from: Date())).geodatabase"
        
        self.generateOfflineMapJob = self.offlineMapTask.generateOfflineMapJob(with: self.parameters, downloadDirectory: URL(string: fullPath)!)
        
        //add observer for progress
        self.generateOfflineMapJob.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        
        //unhide the progress parent view
        self.progressParentView.isHidden = false
        
        //start the job
        self.generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let strongSelf = self else {
                return
            }
            
            //remove KVO observer
            strongSelf.generateOfflineMapJob.progress.removeObserver(strongSelf, forKeyPath: "fractionCompleted")
            
            if let error = error {
                
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            } else {
    
                //disable cancel button
                strongSelf.cancelButton.isEnabled = false
                
                //assign offline map to map view
                strongSelf.mapView.map = result?.offlineMap
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            if keyPath == "fractionCompleted" {
                
                let progress = strongSelf.generateOfflineMapJob.progress
                
                //update progress label
                self?.progressLabel.text = progress.localizedDescription
                
                //update progress view
                self?.progressView.progress = Float(progress.fractionCompleted)
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func action() {
        self.defaultParameters()
        
        //disable bar button item
        self.barButtonItem.isEnabled = false
        
        //hide the extent view
        self.extentView.isHidden = true
    }
    
    @IBAction func cancelAction() {
        
        //cancel generate offline map job
        self.generateOfflineMapJob.progress.cancel()
        
        self.progressParentView.isHidden = true
        self.progressView.progress = 0
        self.progressLabel.text = ""
        
        //enable take map offline bar button item
        self.barButtonItem.isEnabled = true
        
        //unhide the extent view
        self.extentView.isHidden = false
    }
    
    //MARK: - Helper methods
    
    private func showAlert() {
        
        let alertController = UIAlertController(title: nil, message: "This sample requires you to login in order to take the map's basemap offline. Would like to continue?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            self?.addMap()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel)
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convert(self.extentView.frame, from: self.view)
        
        let minPoint = self.mapView.screen(toLocation: frame.origin)
        let maxPoint = self.mapView.screen(toLocation: CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }

    deinit {
        
        guard let progress = self.generateOfflineMapJob?.progress else {
            return
        }
        
        let isCompleted = (progress.totalUnitCount == progress.completedUnitCount)
        let isCancelled = progress.isCancelled
        
        if !isCancelled && !isCompleted {
            //remove observer
            self.generateOfflineMapJob?.progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }
}
