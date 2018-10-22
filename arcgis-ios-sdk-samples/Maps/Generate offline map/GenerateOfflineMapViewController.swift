//
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
    
    private var portalItem:AGSPortalItem?
    private var parameters:AGSGenerateOfflineMapParameters?
    private var offlineMapTask:AGSOfflineMapTask?
    private var generateOfflineMapJob:AGSGenerateOfflineMapJob?
    private var shouldShowAlert = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateOfflineMapViewController"]

        //prepare the authentication manager for user login (required for taking the sample's basemap offline)
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowAlert {
            
            shouldShowAlert = false
            showLoginQueryAlert()
        }
    }
    
    private func addMap() {
        
        //portal for the web map
        let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
        
        //portal item for web map
        let portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        self.portalItem = portalItem
        
        //map from portal item
        let map = AGSMap(item: portalItem)
        
        //assign map to the map view
        mapView.map = map
        
        //disable the bar button item until the map loads
        mapView.map?.load { [weak self] (error) in
            
            guard let self = self else{
                return
            }
            
            if let error = error{
                if (error as NSError).code != NSUserCancelledError{
                    //show error
                    self.presentAlert(error: error)
                }
                return
            }
            
            self.title = self.mapView.map?.item?.title
            self.barButtonItem.isEnabled = true
        }
        
        //instantiate offline map task
        offlineMapTask = AGSOfflineMapTask(portalItem: portalItem)
        
        //setup extent view
        extentView.layer.borderColor = UIColor.red.cgColor
        extentView.layer.borderWidth = 3
    }
    
    private func takeMapOffline() {

        guard let offlineMapTask = offlineMapTask,
            let parameters = parameters else{
            return
        }
        
        let downloadDirectory = getNewOfflineMapDirectoryURL()
        
        let generateOfflineMapJob = offlineMapTask.generateOfflineMapJob(with: parameters, downloadDirectory: downloadDirectory)
        self.generateOfflineMapJob = generateOfflineMapJob
        
        //add observer for progress
        generateOfflineMapJob.progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: nil)
        
        //unhide the progress parent view
        progressParentView.isHidden = false
        
        //start the job
        generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let self = self else {
                return
            }
            
            //remove KVO observer
            self.generateOfflineMapJob?.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            
            if let error = error {    
                //do not display error if user simply cancelled the request
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                }
            }
            else if let result = result {
                self.offlineMapGenerationDidSucceed(with: result)
            }
        }
    }
    
    /// Called when the generate offline map job finishes successfully.
    ///
    /// - Parameter result: The result of the generate offline map job.
    func offlineMapGenerationDidSucceed(with result: AGSGenerateOfflineMapResult) {
        // Show any layer or table errors to the user.
        if let layerErrors = result.layerErrors as? [AGSLayer: Error],
            let tableErrors = result.tableErrors as? [AGSFeatureTable: Error],
            !(layerErrors.isEmpty && tableErrors.isEmpty) {
            
            let errorMessages = layerErrors.map { "\($0.key.name): \($0.value.localizedDescription)" } +
                tableErrors.map { "\($0.key.displayName): \($0.value.localizedDescription)" }
            
            presentAlert(title:"Offline Map Generated with Errors",
                         message: "The following error(s) occurred while generating the offline map:\n\n\(errorMessages.joined(separator: "\n"))")
        }
        
        //disable cancel button
        cancelButton.isEnabled = false
        
        //assign offline map to map view
        mapView.map = result.offlineMap
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(Progress.fractionCompleted) {
            
            DispatchQueue.main.async { [weak self] in
                
                guard let self = self,
                    let progress = self.generateOfflineMapJob?.progress else {
                    return
                }
                
                //update progress label
                self.progressLabel.text = progress.localizedDescription
                
                //update progress view
                self.progressView.progress = Float(progress.fractionCompleted)
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func generateOfflineMapAction() {
        
        //disable bar button item
        barButtonItem.isEnabled = false
        
        //hide the extent view
        extentView.isHidden = true
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Getting default parameters")
        
        //get the area outlined by the extent view
        let areaOfInterest = extentViewFrameToEnvelope()
        
        //default parameters for offline map task
        offlineMapTask?.defaultGenerateOfflineMapParameters(withAreaOfInterest: areaOfInterest) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            guard let parameters = parameters,
                let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
                return
            }
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            //will need the parameters for creating the job later
            self.parameters = parameters
            
            //take map offline
            self.takeMapOffline()
        }

    }
    
    @IBAction func cancelAction() {
        
        //cancel generate offline map job
        generateOfflineMapJob?.progress.cancel()
        
        progressParentView.isHidden = true
        progressView.progress = 0
        progressLabel.text = ""
        
        //enable take map offline bar button item
        barButtonItem.isEnabled = true
        
        //unhide the extent view
        extentView.isHidden = false
    }
    
    //MARK: - Helper methods
    
    private func showLoginQueryAlert() {
        
        let alertController = UIAlertController(title: nil, message: "This sample requires you to login in order to take the map's basemap offline. Would you like to continue?", preferredStyle: .alert)
        let loginAction = UIAlertAction(title: "Login", style: .default) { [weak self] (action) in
            self?.addMap()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        alertController.addAction(loginAction)
        alertController.preferredAction = loginAction
        present(alertController, animated: true, completion: nil)
    }
    
    private func extentViewFrameToEnvelope() -> AGSEnvelope {
        
        let frame = mapView.convert(extentView.frame, from: view)
        
        //the lower-left corner
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        //the upper-right corner
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        //return the envenlope covering the entire extent frame
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    private func getNewOfflineMapDirectoryURL()->URL{

        //get a suitable directory to place files
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        //create a unique name based on current timestamp
        let formattedDate = ISO8601DateFormatter().string(from: Date())
        
        return documentDirectoryURL.appendingPathComponent("\(formattedDate)")
    }

    deinit {
        
        guard let progress = generateOfflineMapJob?.progress else {
            return
        }
        
        let isCompleted = (progress.totalUnitCount == progress.completedUnitCount)
        let isCancelled = progress.isCancelled
        
        if !isCancelled && !isCompleted {
            //remove observer
            progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        }
    }
}
