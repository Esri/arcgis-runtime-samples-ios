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
    
    /// The levels of the floor-aware web map, with an addition of `nil`.
    var levels: [AGSFloorLevel?] = [nil]
    
    // MARK: Methods
    
    /// Set the selected level to visible and all other levels to invisible.
    /// - Parameter selectedLevel: The `AGSFloorLevel` selected.
    func setVisibleFloorLevel(_ selectedLevel: AGSFloorLevel?) {
        levels.forEach { level in
            level?.isVisible = level == selectedLevel
        }
    }
    
    func setPickerViewLayout() {
        floorLevelPickerView.translatesAutoresizingMaskIntoConstraints = false
        let margin: CGFloat = 10.0
        floorLevelPickerView.layer.cornerRadius = margin
        NSLayoutConstraint.activate([
            floorLevelPickerView.widthAnchor.constraint(equalToConstant: 120.0),
            floorLevelPickerView.bottomAnchor.constraint(equalTo: mapView.attributionTopAnchor, constant: -margin),
            floorLevelPickerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin)
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
            guard error == nil, let self = self,
                  // The floor manager of the web map, which exposes the sites,
                  // facilities, and levels of the floor-aware data model.
                  let floorManager = map.floorManager else { return }
            
            floorManager.load { error in
                guard error == nil, let geometry = floorManager.sites.first?.geometry else { return }
                // Set the loaded web map to the map view and set its viewpoint.
                self.mapView.setViewpointGeometry(geometry)
                
                // Update floor picker and select the first floor.
                self.levels += floorManager.levels
                let firstFloorIndex = self.levels.firstIndex { $0?.longName == "Level 1" }!
                self.setVisibleFloorLevel(self.levels[firstFloorIndex])
                self.floorLevelPickerView.reloadAllComponents()
                self.floorLevelPickerView.selectRow(firstFloorIndex, inComponent: 0, animated: true)
            }
        }
        return map
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

// MARK: - UIPickerViewDataSource and UIPickerViewDelegate

extension BrowseBuildingFloorsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        levels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        levels[row]?.shortName ?? "None"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        setVisibleFloorLevel(levels[row])
    }
}
