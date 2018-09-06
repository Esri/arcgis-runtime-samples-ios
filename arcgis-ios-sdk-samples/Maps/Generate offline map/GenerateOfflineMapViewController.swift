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
            showAlert()
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
            
            if let error = error{
                if (error as NSError).code != NSUserCancelledError{
                    //show error
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
                return
            }
            
            guard let strongSelf = self else{
                return
            }
            
            strongSelf.title = strongSelf.mapView.map?.item?.title
            strongSelf.barButtonItem.isEnabled = true
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
        
        let downloadDirectory = getNewOfflineGeodatabaseURL()
        
        let generateOfflineMapJob = offlineMapTask.generateOfflineMapJob(with: parameters, downloadDirectory: downloadDirectory)
        self.generateOfflineMapJob = generateOfflineMapJob
        
        //add observer for progress
        generateOfflineMapJob.progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: nil)
        
        //unhide the progress parent view
        progressParentView.isHidden = false
        
        //start the job
        generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let strongSelf = self else {
                return
            }
            
            //remove KVO observer
            strongSelf.generateOfflineMapJob?.progress.removeObserver(strongSelf, forKeyPath: #keyPath(Progress.fractionCompleted))
            
            if let error = error {    
                //do not display error if user simply cancelled the request
                if (error as NSError).code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            }
            else if let result = result {
                strongSelf.offlineMapGenerationDidSucceed(with: result)
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
            let okayAction = UIAlertAction(title: "OK", style: .default)
            let alertController = UIAlertController(
                title: "Offline Map Generated with Errors",
                message: "The following error(s) occurred while generating the offline map:\n\n\(errorMessages.joined(separator: "\n"))",
                preferredStyle: .alert
            )
            alertController.addAction(okayAction)
            alertController.preferredAction = okayAction
            present(alertController, animated: true)
        }
        
        //disable cancel button
        cancelButton.isEnabled = false
        
        //assign offline map to map view
        mapView.map = result.offlineMap
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "fractionCompleted" {
            
            DispatchQueue.main.async { [weak self] in
                
                guard let strongSelf = self,
                    let progress = strongSelf.generateOfflineMapJob?.progress else {
                    return
                }
                
                //update progress label
                strongSelf.progressLabel.text = progress.localizedDescription
                
                //update progress view
                strongSelf.progressView.progress = Float(progress.fractionCompleted)
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func action() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Getting default parameters")
        
        //default parameters for offline map task
        offlineMapTask?.defaultGenerateOfflineMapParameters(withAreaOfInterest: frameToExtent()) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                return
            }
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let parameters = parameters,
                let strongSelf = self else {
                return
            }
            
            //will need the parameters for creating the job later
            strongSelf.parameters = parameters
            
            //take map offline
            strongSelf.takeMapOffline()
        }
        
        //disable bar button item
        barButtonItem.isEnabled = false
        
        //hide the extent view
        extentView.isHidden = true
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
    
    private func showAlert() {
        
        let alertController = UIAlertController(title: nil, message: "This sample requires you to login in order to take the map's basemap offline. Would you like to continue?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            self?.addMap()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel)
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    private func getNewOfflineGeodatabaseURL()->URL{
        //create a unique name for the geodatabase based on current timestamp
        let formattedDate = ISO8601DateFormatter().string(from: Date())
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fullPath = "\(path)/\(formattedDate).geodatabase"
        let fullPathURL = URL(string: fullPath)!
        return fullPathURL
    }

    deinit {
        
        guard let generateOfflineMapJob = generateOfflineMapJob else {
            return
        }
        let progress = generateOfflineMapJob.progress
        
        let isCompleted = (progress.totalUnitCount == progress.completedUnitCount)
        let isCancelled = progress.isCancelled
        
        if !isCancelled && !isCompleted {
            //remove observer
            generateOfflineMapJob.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        }
    }
}
