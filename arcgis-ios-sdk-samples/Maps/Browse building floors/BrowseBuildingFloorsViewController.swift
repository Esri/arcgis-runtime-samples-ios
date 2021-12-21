// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class BrowseBuildingFloorsViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The floor level picker view.
    @IBOutlet var floorLevelPickerView: UIPickerView!
    
    // MARK: Properties
    
    /// The floor levels of the floor-aware web map.
    var floorLevels: [AGSFloorLevel] = []
    
    /// The currently selected floor level.
    var selectedFloorLevel: AGSFloorLevel? {
        didSet {
            // Set the selected level to visible and the previous to invisible.
            oldValue?.isVisible = false
            selectedFloorLevel?.isVisible = true
            // Update picker view selection.
            let row: Int
            if let selectedFloorLevel = selectedFloorLevel {
                row = floorLevels.firstIndex(of: selectedFloorLevel)! + 1
            } else {
                row = .zero
            }
            floorLevelPickerView.selectRow(row, inComponent: 0, animated: true)
        }
    }
    
    // MARK: Methods
    
    func setPickerViewLayout() {
        floorLevelPickerView.translatesAutoresizingMaskIntoConstraints = false
        floorLevelPickerView.layer.cornerRadius = 10.0
        NSLayoutConstraint.activate([
            floorLevelPickerView.widthAnchor.constraint(equalToConstant: 120.0),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: floorLevelPickerView.trailingAnchor, multiplier: 1),
            mapView.attributionTopAnchor.constraint(equalToSystemSpacingBelow: floorLevelPickerView.bottomAnchor, multiplier: 1)
        ])
    }
    
    /// Create a map.
    func makeMap() -> AGSMap {
        // A floor-aware web map for floors of Esri Building L in Redlands.
        let map = AGSMap(item: AGSPortalItem(
            portal: .arcGISOnline(withLoginRequired: false),
            itemID: "f133a698536f44c8884ad81f80b6cfc7"
        ))
        map.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.mapDidLoad(map)
            }
        }
        return map
    }
    
    /// Called after the web map is loaded without error.
    func mapDidLoad(_ map: AGSMap) {
        // The floor manager of the web map, which exposes the sites,
        // facilities, and levels of the floor-aware data model.
        guard let floorManager = map.floorManager else { return }
        floorManager.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.floodManagerDidLoad(floorManager)
            }
        }
    }
    
    /// Called after the floor manager of the web map is loaded without error.
    func floodManagerDidLoad(_ floorManager: AGSFloorManager) {
        guard let geometry = floorManager.sites.first?.geometry,
              let firstFloor = floorManager.levels.first(where: { $0.longName == "Level 1" }) else { return }
        mapView.setViewpointGeometry(geometry)
        // Update floor levels and select the first floor.
        floorLevels = floorManager.levels
        floorLevelPickerView.reloadAllComponents()
        selectedFloorLevel = firstFloor
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["BrowseBuildingFloorsViewController"]
        // Set the appearance of the floor level picker view.
        setPickerViewLayout()
    }
}

// MARK: - UIPickerViewDataSource

extension BrowseBuildingFloorsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        floorLevels.count + 1
    }
}

// MARK: - UIPickerViewDelegate

extension BrowseBuildingFloorsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let index = row - 1
        return index >= floorLevels.startIndex ? floorLevels[index].shortName : "None"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let index = row - 1
        selectedFloorLevel = index >= floorLevels.startIndex ? floorLevels[index] : nil
    }
}
