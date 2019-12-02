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

/// A view controller that manages the interface of the Apply Scheduled Updates
/// to Preplanned Map Area sample.
class ApplyScheduledUpdatesToPreplannedMapAreaViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView!
    
    /// The mobile map package used by this sample.
    let mobileMapPackage: AGSMobileMapPackage!
    /// The sync task used to check for scheduled updates.
    var offlineMapSyncTask: AGSOfflineMapSyncTask!
    /// The sync job used to apply updates to the offline map.
    var offlineMapSyncJob: AGSOfflineMapSyncJob!
    
    required init?(coder: NSCoder) {
        let mobileMapPackageURL = Bundle.main.url(forResource: "canyonlands", withExtension: nil)!
        do {
            let temporaryDirectoryURL = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: mobileMapPackageURL,
                create: true
            )
            let temporaryMobileMapPackageURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            try FileManager.default.copyItem(at: mobileMapPackageURL, to: temporaryMobileMapPackageURL)
            mobileMapPackage = AGSMobileMapPackage(fileURL: temporaryMobileMapPackageURL)
        } catch {
            print("Error setting up mobile map package: \(error)")
            mobileMapPackage = nil
        }
        
        super.init(coder: coder)
        
        mobileMapPackage?.load { [weak self] (error) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            self?.mobileMapPackageDidLoad(with: result)
        }
    }
    
    deinit {
        if let mobileMapPackage = mobileMapPackage {
            mobileMapPackage.close()
            try? FileManager.default.removeItem(at: mobileMapPackage.fileURL)
        }
    }
    
    /// Called in response to the mobile map package load operation completing.
    /// - Parameter result: The result of the load operation.
    func mobileMapPackageDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            let map = self.mobileMapPackage.maps.first!
            loadViewIfNeeded()
            mapView.map = map
            let offlineMapSyncTask = AGSOfflineMapSyncTask(map: map)
            offlineMapSyncTask.checkForUpdates { [weak self] (updatesInfo, error) in
                if let updatesInfo = updatesInfo {
                    self?.offlineMapSyncTaskDidComplete(with: .success(updatesInfo))
                } else if let error = error {
                    self?.offlineMapSyncTaskDidComplete(with: .failure(error))
                }
            }
            self.offlineMapSyncTask = offlineMapSyncTask
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Called in response to the offline map sync task completing.
    /// - Parameter result: The result of the sync task.
    func offlineMapSyncTaskDidComplete(with result: Result<AGSOfflineMapUpdatesInfo, Error>) {
        switch result {
        case .success(let updatesInfo):
            let alertController: UIAlertController
            if updatesInfo.downloadAvailability == .available {
                let downloadSize = updatesInfo.scheduledUpdatesDownloadSize
                let downloadSizeString: String
                if #available(iOS 13.0, *) {
                    let measurement = Measurement(
                        value: Double(downloadSize),
                        unit: UnitInformationStorage.bytes
                    )
                    downloadSizeString = ByteCountFormatter.string(from: measurement, countStyle: .file)
                } else {
                    downloadSizeString = ByteCountFormatter.string(fromByteCount: Int64(downloadSize), countStyle: .file)
                }
                alertController = UIAlertController(
                    title: "Scheduled Updates Available",
                    message: "A \(downloadSizeString) update is available. Would you like to apply it?",
                    preferredStyle: .alert
                )
                let applyAction = UIAlertAction(title: "Apply", style: .default) { (_) in
                    self.applyScheduledUpdates()
                }
                alertController.addAction(applyAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alertController.addAction(cancelAction)
                alertController.preferredAction = applyAction
            } else {
                alertController = UIAlertController(
                    title: "Scheduled Updates Unavailable",
                    message: "There are no updates available.",
                    preferredStyle: .alert
                )
                let okayAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(okayAction)
                alertController.preferredAction = okayAction
            }
            present(alertController, animated: true)
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Apply available updates to the offline map.
    func applyScheduledUpdates() {
        offlineMapSyncTask.defaultOfflineMapSyncParameters { [weak self] (parameters, error) in
            guard let self = self else { return }
            if let parameters = parameters {
                let offlineMapSyncJob = self.offlineMapSyncTask.offlineMapSyncJob(with: parameters)
                offlineMapSyncJob.start(statusHandler: nil) { [weak self] (result, error) in
                    if let result = result {
                        self?.offlineMapSyncJobDidComplete(with: .success(result))
                    } else if let error = error {
                        self?.offlineMapSyncJobDidComplete(with: .failure(error))
                    }
                }
                self.offlineMapSyncJob = offlineMapSyncJob
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Called in response to the offline map sync job completing.
    /// - Parameter result: The result of the sync job.
    func offlineMapSyncJobDidComplete(with result: Result<AGSOfflineMapSyncResult, Error>) {
        switch result {
        case .success(let result):
            guard result.isMobileMapPackageReopenRequired else {
                break
            }
            mobileMapPackage.close()
            mobileMapPackage.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.mapView.map = self.mobileMapPackage.maps.first
                }
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "ApplyScheduledUpdatesToPreplannedMapAreaViewController"
        ]
    }
}
