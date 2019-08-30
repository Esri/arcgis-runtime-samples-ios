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

/// A view controller that manages the interface of the Generate Offline Map
/// (Basemap by Reference) sample.
class GenerateOfflineMapBasemapByReferenceViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Set inset of overlay.
            let padding: CGFloat = 30
            mapView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        }
    }
    /// The view used to show the geographic area for which the map data should
    /// be taken offline.
    @IBOutlet weak var areaOfInterestView: UIView!
    /// The button item that starts generating an offline map.
    @IBOutlet weak var generateButtonItem: UIBarButtonItem!
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        let portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        let map = AGSMap(item: portalItem)
        map.load { [weak self] _ in self?.mapDidLoad() }
        return map
    }
    
    /// Called in response to the map load operation completing.
    func mapDidLoad() {
        guard let map = mapView.map else { return }
        if let error = map.loadError {
            presentAlert(error: error)
        } else {
            generateButtonItem.isEnabled = true
        }
    }
    
    /// Called in response to the Generate Offline Map button item being tapped.
    @IBAction func generateOfflineMap() {
        generateButtonItem.isEnabled = false
        mapView.isUserInteractionEnabled = false
        let offlineMapTask = AGSOfflineMapTask(onlineMap: mapView.map!)
        offlineMapTask.defaultGenerateOfflineMapParameters(withAreaOfInterest: areaOfInterest) { [weak self] (parameters, error) in
            if let parameters = parameters {
                self?.offlineMapTask(offlineMapTask, didCreate: parameters)
            } else if let error = error {
                self?.offlineMapTask(offlineMapTask, didFailToCreateParametersWith: error)
            }
        }
    }
    
    func offlineMapTask(_ offlineMapTask: AGSOfflineMapTask, didCreate parameters: AGSGenerateOfflineMapParameters) {
        let filename = parameters.referenceBasemapFilename as NSString
        let name = filename.deletingPathExtension
        let `extension` = filename.pathExtension
        if let url = Bundle.main.url(forResource: name, withExtension: `extension`) {
            let message: String = {
                let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
                return String(format: "“%@” has a local version of the basemap used by the map. Would you like to use the local or the online basemap?", displayName)
            }()
            let alertController = UIAlertController(title: "Choose Basemap", message: message, preferredStyle: .actionSheet)
            let offlineAction = UIAlertAction(title: "Local", style: .default) { (_) in
                parameters.referenceBasemapDirectory = url.deletingLastPathComponent()
                self.takeMapOffline(task: offlineMapTask, parameters: parameters)
            }
            alertController.addAction(offlineAction)
            let onlineAction = UIAlertAction(title: "Online", style: .default) { (_) in
                self.takeMapOffline(task: offlineMapTask, parameters: parameters)
            }
            alertController.addAction(onlineAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                self.generateButtonItem.isEnabled = true
                self.mapView.isUserInteractionEnabled = true
            }
            alertController.addAction(cancelAction)
            alertController.preferredAction = offlineAction
            alertController.popoverPresentationController?.barButtonItem = generateButtonItem
            present(alertController, animated: true)
        } else {
            takeMapOffline(task: offlineMapTask, parameters: parameters)
        }
    }
    
    func offlineMapTask(_ offlineMapTask: AGSOfflineMapTask, didFailToCreateParametersWith error: Error) {
        presentAlert(error: error)
        generateButtonItem.isEnabled = true
        mapView.isUserInteractionEnabled = true
    }
    
    /// The geographic area for which the map data should be taken offline.
    var areaOfInterest: AGSEnvelope {
        let frame = mapView.convert(areaOfInterestView.frame, from: view)
        // The lower-left corner.
        let minPoint = mapView.screen(toLocation: frame.origin)
        // The upper-right corner.
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    /// The generate offline map job.
    var generateOfflineMapJob: AGSGenerateOfflineMapJob?
    /// The view that displays the progress of the job.
    var downloadProgressView: DownloadProgressView?
    
    func takeMapOffline(task offlineMapTask: AGSOfflineMapTask, parameters: AGSGenerateOfflineMapParameters) {
        guard let downloadDirectoryURL = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: Bundle.main.bundleURL, create: true).appendingPathComponent(UUID().uuidString) else {
            assertionFailure("Could not create temporary directory.")
            return
        }
        let job = offlineMapTask.generateOfflineMapJob(with: parameters, downloadDirectory: downloadDirectoryURL)
        job.start(statusHandler: nil) { [weak self] (result, error) in
            guard let self = self else { return }
            if let result = result {
                self.offlineMapGenerationDidSucceed(with: result)
            } else if let error = error {
                self.offlineMapGenerationDidFail(with: error)
            }
        }
        self.generateOfflineMapJob = job
        let downloadProgressView = DownloadProgressView()
        downloadProgressView.delegate = self
        downloadProgressView.show(withStatus: "Generating ofline map…", progress: 0)
        downloadProgressView.observedProgress = job.progress
        self.downloadProgressView = downloadProgressView
    }
    
    /// Called when the generate offline map job finishes successfully.
    ///
    /// - Parameter result: The result of the generate offline map job.
    func offlineMapGenerationDidSucceed(with result: AGSGenerateOfflineMapResult) {
        // Dismiss download progress view.
        downloadProgressView?.dismiss()
        downloadProgressView = nil
        
        // Show any layer or table errors to the user.
        if let layerErrors = result.layerErrors as? [AGSLayer: Error],
            let tableErrors = result.tableErrors as? [AGSFeatureTable: Error],
            !(layerErrors.isEmpty && tableErrors.isEmpty) {
            let errorMessages = layerErrors.map { "\($0.key.name): \($0.value.localizedDescription)" } +
                tableErrors.map { "\($0.key.displayName): \($0.value.localizedDescription)" }
            
            let message: String = {
               let format = "The following error(s) occurred while generating the offline map:\n\n%@"
                return String(format: format, errorMessages.joined(separator: "\n"))
            }()
            presentAlert(title: "Offline Map Generated with Errors", message: message)
        }
        
        areaOfInterestView.isHidden = true
        mapView.map = result.offlineMap
        mapView.setViewpoint(AGSViewpoint(targetExtent: areaOfInterest))
        mapView.isUserInteractionEnabled = true
    }
    
    /// Called when the generate offline map job fails.
    ///
    /// - Parameter error: The error that caused the generation to fail.
    func offlineMapGenerationDidFail(with error: Error) {
        if (error as NSError).code != NSUserCancelledError {
            self.presentAlert(error: error)
        }
        self.generateButtonItem.isEnabled = true
        mapView.isUserInteractionEnabled = true
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "GenerateOfflineMapBasemapByReferenceViewController"
        ]
    }
}

extension GenerateOfflineMapBasemapByReferenceViewController: DownloadProgressViewDelegate {
    func downloadProgressViewDidCancel(_ downloadProgressView: DownloadProgressView) {
        downloadProgressView.observedProgress?.cancel()
        self.generateButtonItem.isEnabled = true
        mapView.isUserInteractionEnabled = true
    }
}

@IBDesignable
class GenerateOfflineMapBasemapByReferenceOverlayView: UIView {
    @IBInspectable var borderColor: UIColor? {
        get {
            return layer.borderColor.map(UIColor.init(cgColor:))
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
}
