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

class GenerateOfflineMapOverridesViewController: UIViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var extentView: UIView!
    @IBOutlet weak var generateButtonItem: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressParentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    private var portalItem: AGSPortalItem?
    private var parameters: AGSGenerateOfflineMapParameters?
    private var parameterOverrides: AGSGenerateOfflineMapParameterOverrides?
    private var offlineMapTask: AGSOfflineMapTask?
    private var generateOfflineMapJob: AGSGenerateOfflineMapJob?
    private var shouldShowAlert = true
    
    private var progressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateOfflineMapOverridesViewController", "OfflineMapParameterOverridesViewController"]

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //remove key-value observation
        progressObservation = nil
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
        
        // load the map
        mapView.map?.load { [weak self] (error) in
            
            guard let self = self else{
                return
            }
            
            if let error = error{
                // don't show an error if the user cancelled from the login screen
                if (error as NSError).code != NSUserCancelledError{
                    //show error
                    self.presentAlert(error: error)
                }
                return
            }
            
            self.title = self.mapView.map?.item?.title
            self.generateButtonItem.isEnabled = true
        }
        
        //instantiate offline map task
        offlineMapTask = AGSOfflineMapTask(portalItem: portalItem)
        
        //setup extent view
        extentView.layer.borderColor = UIColor.red.cgColor
        extentView.layer.borderWidth = 3
    }
    
    private func takeMapOffline() {

        guard let offlineMapTask = offlineMapTask,
            let parameters = parameters,
            let parameterOverrides = parameterOverrides else{
            return
        }
        
        let downloadDirectory = getNewOfflineGeodatabaseURL()
        
        let generateOfflineMapJob = offlineMapTask.generateOfflineMapJob(with: parameters,
                                                                         parameterOverrides: parameterOverrides,
                                                                         downloadDirectory: downloadDirectory)
        self.generateOfflineMapJob = generateOfflineMapJob
        
        progressObservation = generateOfflineMapJob.progress.observe(\.fractionCompleted, options: .initial) {[weak self] (progress, _) in
            DispatchQueue.main.async { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                //update progress label
                self.progressLabel.text = progress.localizedDescription
                
                //update progress view
                self.progressView.progress = Float(progress.fractionCompleted)
            }
        }
        
        //unhide the progress parent view
        progressParentView.isHidden = false
        
        //start the job
        generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let self = self else {
                return
            }
            
            //remove key-value observation
            self.progressObservation = nil
            
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
    
    
    func openParameterOverridesViewController(){
        //instantiate the view controller
        let paramNavigationController = storyboard!.instantiateViewController(withIdentifier: "OfflineParametersNavigationController") as! UINavigationController
        let paramController = paramNavigationController.viewControllers.first as! OfflineMapParameterOverridesViewController
        paramController.parameterOverrides = parameterOverrides
        paramController.map = mapView.map
        
        // set the completion handler
        paramController.startJobHandler = {[weak self] (paramController) in
            // start the job
            self?.takeMapOffline()
            // close the view
            paramController.navigationController?.dismiss(animated: true)
        }
        paramController.cancelHandler = {[weak self] (paramController) in
            // reset the UI
            self?.resetUIForOfflineMapGeneration()
            // close the view
            paramController.navigationController?.dismiss(animated: true)
        }
        //display the parameters sheet
        present(paramNavigationController, animated: true)
    }
    
    func resetUIForOfflineMapGeneration(){
        
        // close and reset the progress view
        progressParentView.isHidden = true
        progressView.progress = 0
        progressLabel.text = ""
        
        //enable take map offline bar button item
        generateButtonItem.isEnabled = true
        //unhide the extent view
        extentView.isHidden = false
    }
    
    //MARK: - Actions
    
    @IBAction func generateOfflineMapAction() {
        
        guard let offlineMapTask = offlineMapTask else {
            return
        }
        
        //disable bar button item
        generateButtonItem.isEnabled = false
        //hide the extent view
        extentView.isHidden = true
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Getting default parameters")
        
        //get the area outlined by the extent view
        let areaOfInterest = extentViewFrameToEnvelope()
        
        //default parameters for offline map task
        offlineMapTask.defaultGenerateOfflineMapParameters(withAreaOfInterest: areaOfInterest) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
                return
            }
            
            guard let parameters = parameters else {
                return
            }
            
            //will need the parameters for creating the job later
            self.parameters = parameters
            
            //build the parameter overrides object to be configured by the user
            offlineMapTask.generateOfflineMapParameterOverrides(with: parameters, completion: {[weak self] (parameterOverrides, error) in
                
                guard let self = self else{
                    return
                }
                
                if let error = error {
                    self.presentAlert(error: error)
                    return
                }
                
                guard let parameterOverrides = parameterOverrides else{
                    return
                }
                self.parameterOverrides = parameterOverrides
                
                //now that we have the override object, show the overrides UI
                self.openParameterOverridesViewController()
            })
            
        }

    }
    
    @IBAction func cancelAction() {
        
        //cancel generate offline map job
        generateOfflineMapJob?.progress.cancel()
        
        resetUIForOfflineMapGeneration()
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
        present(alertController, animated: true)
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
    
    private func getNewOfflineGeodatabaseURL()->URL{

        //get a suitable directory to place files
        let directoryURL = FileManager.default.temporaryDirectory
        
        //create a unique name for the geodatabase based on current timestamp
        let formattedDate = ISO8601DateFormatter().string(from: Date())
        
        return directoryURL.appendingPathComponent("\(formattedDate).geodatabase")
    }
    
}
