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

// MARK: - AGSPreplannedMapArea

private extension AGSPreplannedMapArea {
    var mapPackageURL: URL {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        let mapPackageURL = documentsDirectoryURL.appendingPathComponent(portalItemIdentifier).appendingPathExtension("mmpk")
        return mapPackageURL
    }

    var portalItemIdentifier: String {
        return portalItem?.itemID ?? "-"
    }
}

// MARK: - Constants

private enum Constants {
    static let onlineMapCellReuseIdentifier = "OnlineMapCell"
    static let preplannedMapAreaCellReuseIdentifier = "PreplannedMapAreaCell"

    static let webMapRowIndex = 0
}

// MARK: - MapSelectionDelegate

protocol MapSelectionDelegate: AnyObject {
    func didDownloadMapPackageForPreplannedMapArea(_ mapPackage: AGSMobileMapPackage)
    func didSelectMap(map: AGSMap)
}

// MARK: - MapSelectionTableViewSection

private enum MapSelectionTableViewSection: Int, CaseIterable {
    case webMaps = 0
    case preplannedMapAreas
}

extension MapSelectionTableViewSection {
    var headerTitle: String? {
        switch self {
        case .webMaps:              return nil
        case .preplannedMapAreas:   return "Preplanned Map Areas"
        }
    }

    var footererTitle: String? {
        switch self {
        case .webMaps:              return nil
        case .preplannedMapAreas:   return "Tap to download a preplanned map area for offline use. Once downloaded, the map area will be selected."
        }
    }
}

// MARK: - MapSelectionTableViewController

class MapSelectionTableViewController: UITableViewController {
    weak var mapSelectionDelegate: MapSelectionDelegate?

    var currentlySelectedMap: AGSMap!
    var onlineMap: AGSMap!

    var availablePreplannedMapAreas: [AGSPreplannedMapArea]!
    var localMapPackages: [AGSMobileMapPackage]!

    private var offlineTask: AGSOfflineMapTask?
    private var currentJobs = [AGSPreplannedMapArea: AGSDownloadPreplannedOfflineMapJob]()
    private var jobProgressObservations = Set<NSKeyValueObservation>()

    // MARK: UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupView()
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in: UITableView) -> Int {
        return MapSelectionTableViewSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = MapSelectionTableViewSection(rawValue: indexPath.section) else {
            fatalError("Section index (\(indexPath.section)) not found!") // This is a programmer error.
        }

        let cell: UITableViewCell

        switch section {
        case .webMaps:
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.onlineMapCellReuseIdentifier, for: indexPath)
        case .preplannedMapAreas:
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.preplannedMapAreaCellReuseIdentifier, for: indexPath)
            configurePreplannedMapAreaCell(cell, atIndexPath: indexPath)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = MapSelectionTableViewSection(rawValue: section) else {
            return 0
        }

        switch section {
        case .webMaps:
            return 1
        case .preplannedMapAreas:
            return availablePreplannedMapAreas.count
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = MapSelectionTableViewSection(rawValue: indexPath.section) else {
            return
        }

        let rowIndex = indexPath.row

        switch section {
        case .webMaps:
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            mapSelectionDelegate?.didSelectMap(map: onlineMap)
        case .preplannedMapAreas:
            guard rowIndex < availablePreplannedMapAreas.count else { return }

            let area = availablePreplannedMapAreas[rowIndex]

            if let mapPackage = localMapPackages.first(where: { return $0.fileURL.path.contains(area.portalItemIdentifier) }), let offlineMap = mapPackage.maps.first {
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                mapSelectionDelegate?.didSelectMap(map: offlineMap)
            } else {
                let selectedCell = tableView.cellForRow(at: indexPath)
                downloadPreplannedMapArea(area, forCell: selectedCell)
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return MapSelectionTableViewSection(rawValue: section)?.footererTitle
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return MapSelectionTableViewSection(rawValue: section)?.headerTitle
    }

    // MARK: Private behavior

    private func configurePreplannedMapAreaCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let rowIndex = indexPath.row
        guard rowIndex < availablePreplannedMapAreas.count else {
            return
        }

        let area = availablePreplannedMapAreas[rowIndex]
        cell.textLabel?.text = area.portalItem?.title ?? ""

        if localMapPackages.contains(where: { return $0.fileURL.path.contains(area.portalItemIdentifier) }) {
            let areaCell = cell as? PreplannedMapAreaTableViewCell
            areaCell?.progressView.progress = 100
        }
    }

    private func downloadPreplannedMapArea(_ area: AGSPreplannedMapArea, forCell cell: UITableViewCell?) {
        guard currentJobs[area] == nil else { return }  // download in progress

        if offlineTask == nil {
            offlineTask = AGSOfflineMapTask(onlineMap: onlineMap)
        }

        guard let task = offlineTask else { return }

        let existingAreaContents = area.mapPackageURL.path
        if FileManager.default.fileExists(atPath: existingAreaContents) {
            try? FileManager.default.removeItem(atPath: existingAreaContents)
        }

        let job = task.downloadPreplannedOfflineMapJob(with: area, downloadDirectory: area.mapPackageURL)
        currentJobs[area] = job

        let observation = job.progress.observe(\.fractionCompleted, options: .new) { (progress, change) in
            DispatchQueue.main.async {
                let downloadCell = cell as? PreplannedMapAreaTableViewCell
                downloadCell?.progressView.progress = Float(progress.fractionCompleted)
            }
        }
        jobProgressObservations.insert(observation)

        job.start(statusHandler: nil) { [weak self, unowned observation] (result, error) in
            self?.jobProgressObservations.remove(observation)

            if let error = error {
                print("Error downloading the preplanned map : \(error.localizedDescription)")
                return
            }

            guard let result = result else { return }

            let localMapPackage = result.mobileMapPackage
            self?.localMapPackages.append(localMapPackage)
            self?.mapSelectionDelegate?.didDownloadMapPackageForPreplannedMapArea(localMapPackage)

            let map = result.offlineMap
            self?.mapSelectionDelegate?.didSelectMap(map: map)

            cell?.accessoryType = .checkmark
        }
    }

    private func setupView() {
        let initialIndexPath: IndexPath?
        if currentlySelectedMap == onlineMap {
            initialIndexPath = IndexPath(row: Constants.webMapRowIndex, section: MapSelectionTableViewSection.webMaps.rawValue)
        } else if let package = localMapPackages.first(where: { return currentlySelectedMap == $0.maps.first }),
            let areaIndex = availablePreplannedMapAreas.firstIndex(where: { return package.fileURL.path.contains($0.portalItemIdentifier) }) {
            initialIndexPath = IndexPath(row: areaIndex, section: MapSelectionTableViewSection.preplannedMapAreas.rawValue)
        } else {
            initialIndexPath = nil
        }

        if let indexPath = initialIndexPath {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
}
