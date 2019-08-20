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

// MARK: - Constants

private enum Constants {
    static let activityIndicatorColor = UIColor.primaryBlue

    static let portalItemIdentifier = "acc027394bc84c2fb04d1ed317aac674"

    static let popoverPreferredWidth: CGFloat = 375
    static let popoverPreferredCompactHeight: CGFloat = 280
    static let popoverPreferredRegularHeight: CGFloat = 360
}

// MARK: - DownloadPreplannedMapViewController

class DownloadPreplannedMapViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var selectMapBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var removeDownloadsBarButtonItem: UIBarButtonItem!

    private let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
    private var portalItem: AGSPortalItem?
    private var onlineMap: AGSMap?

    private var offlineTask: AGSOfflineMapTask?
    private var cancelable: AGSCancelable?

    private var remoteAvailablePreplannedMapAreas = [AGSPreplannedMapArea]()

    private var remoteLoadedPreplannedMapAreas = [AGSPreplannedMapArea]() {
        didSet {
            updateView()
        }
    }

    private var uniqueLocalMapPackages = Set<AGSMobileMapPackage>() {
        didSet {
            updateView()
        }
    }

    // MARK: UIViewController

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let viewController = navigationController.viewControllers.first as? MapSelectionTableViewController {
            navigationController.presentationController?.delegate = self

            let height: CGFloat
            if traitCollection.horizontalSizeClass == .regular, traitCollection.verticalSizeClass == .regular {
                height = Constants.popoverPreferredRegularHeight
            } else {
                height = Constants.popoverPreferredCompactHeight
            }
            let contentSize = CGSize(width: Constants.popoverPreferredWidth, height: height)
            viewController.preferredContentSize = contentSize

            viewController.mapSelectionDelegate = self
            viewController.currentlySelectedMap = mapView.map
            viewController.onlineMap = onlineMap
            viewController.availablePreplannedMapAreas = remoteLoadedPreplannedMapAreas.sorted { $0.title < $1.title }
            viewController.localMapPackages = Array(uniqueLocalMapPackages)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sourceBarButtonItem = navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem else {
            return
        }
        sourceBarButtonItem.filenames = ["DownloadPreplannedMapViewController", "MapSelectionTableViewController", "PreplannedMapAreaTableViewCell"]

        activityIndicatorView.color = Constants.activityIndicatorColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadPortal()
    }

    // MARK: IBActions

    @IBAction private func removeDownloadsTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Delete offline areas?", message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.removeDownloadedMapPackages()
        }
        alertController.addAction(deleteAction)
        alertController.preferredAction = deleteAction

        present(alertController, animated: true)
    }

    // MARK: Private behavior

    private func loadOnlineMap() {
        guard let portalItem = portalItem else { return }

        let onlineMap = AGSMap(item: portalItem)
        mapView.map = onlineMap

        activityIndicatorView.startAnimating()

        onlineMap.load { [weak self] (error) in
            self?.activityIndicatorView.stopAnimating()

            if let error = error {
                print("Error encountered loading the map : \(error.localizedDescription)")
            } else {
                self?.loadPreplannedMapAreas()
            }
        }
        self.onlineMap = onlineMap
    }

    private func loadPortal() {
        guard portal.loadStatus != .loaded else { return }

        let portalItem = AGSPortalItem(portal: portal, itemID: Constants.portalItemIdentifier)
        self.portalItem = portalItem

        activityIndicatorView.startAnimating()

        portal.load { [weak self] (error) in
            self?.activityIndicatorView.stopAnimating()

            if let error = error {
                print("Error encountered loading the portal : \(error.localizedDescription)")
                return
            }

            self?.loadOnlineMap()
            self?.retrieveAvailablePreplannedMapAreas()
        }
    }

    private func loadPreplannedMapAreas() {
        remoteAvailablePreplannedMapAreas.forEach { area in
            activityIndicatorView.startAnimating()

            area.load { [weak self, unowned area] (error) in
                self?.activityIndicatorView.stopAnimating()

                if let error = error {
                    print("Error encountered loading the area : \(error.localizedDescription)")
                    return
                }

                self?.remoteLoadedPreplannedMapAreas.append(area)
            }
        }
    }

    private func removeDownloadedMapPackages() {
        mapView.map = onlineMap

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.uniqueLocalMapPackages.forEach { package in
                let path = package.fileURL.path
                if FileManager.default.fileExists(atPath: path) {
                    try? FileManager.default.removeItem(atPath: path)
                }
            }
            self?.uniqueLocalMapPackages.removeAll()

            DispatchQueue.main.async {
                self?.updateView()
            }
        }
    }

    private func retrieveAvailablePreplannedMapAreas() {
        guard let portalItem = portalItem else { return }

        activityIndicatorView.startAnimating()

        cancelable?.cancel()
        offlineTask = AGSOfflineMapTask(portalItem: portalItem)

        cancelable = offlineTask?.getPreplannedMapAreas { [weak self] (preplannedAreas, error) in
            self?.activityIndicatorView.stopAnimating()

            if let error = error {
                print("Error encountered loading preplanned map areas : \(error.localizedDescription)")
                return
            }

            self?.remoteAvailablePreplannedMapAreas = preplannedAreas ?? []
            self?.loadPreplannedMapAreas()
        }
    }

    private func updateView() {
        selectMapBarButtonItem.isEnabled = !remoteLoadedPreplannedMapAreas.isEmpty
        removeDownloadsBarButtonItem.isEnabled = !uniqueLocalMapPackages.isEmpty
    }
}

// MARK: - MapSelectionDelegate

extension DownloadPreplannedMapViewController: MapSelectionDelegate {
    func didDownloadMapPackageForPreplannedMapArea(_ mapPackage: AGSMobileMapPackage) {
        uniqueLocalMapPackages.insert(mapPackage)
    }

    func didSelectMap(map: AGSMap) {
        mapView.map = map
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension DownloadPreplannedMapViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none    // ensure that the settings are show in a popover even on small displays
    }
}
