// Copyright 2016 Esri.
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

import UIKit
import ArcGIS

protocol CreateOptionsViewControllerDelegate: AnyObject {
    func createOptionsViewController(_ createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer])
}

class CreateOptionsViewController: UITableViewController {
    private let basemaps: [AGSBasemap] = [.streets(), .imagery(), .topographic(), .oceans()]
    private let layers: [AGSLayer] = {
        let layerURLs = [
            URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!,
            URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!
        ]
        return layerURLs.map { AGSArcGISMapImageLayer(url: $0) }
    }()
    
    private var selectedBasemapIndex: Int = 0
    private var selectedLayerIndices: IndexSet = []
    
    weak var delegate: CreateOptionsViewControllerDelegate?

    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Choose Basemap" : "Add Operational Layers"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? basemaps.count : layers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        switch indexPath.section {
        case 0:
            let basemap = basemaps[indexPath.row]
            cell.textLabel?.text = basemap.name
            
            //accesory view
            if selectedBasemapIndex == indexPath.row {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        default:
            let layer = layers[indexPath.row]
            cell.textLabel?.text = layer.name
            
            //accessory view
            if selectedLayerIndices.contains(indexPath.row) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            //create a IndexPath for the previously selected index
            let previousSelectionIndexPath = IndexPath(row: selectedBasemapIndex, section: 0)
            selectedBasemapIndex = indexPath.row
            tableView.reloadRows(at: [indexPath, previousSelectionIndexPath], with: .none)
        case 1:
            //check if already selected
            if selectedLayerIndices.contains(indexPath.row) {
                //remove the selection
                selectedLayerIndices.remove(indexPath.row)
            } else {
                selectedLayerIndices.update(with: indexPath.row)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        default:
            break
        }
    }

    // MARK: - Actions
    
    @IBAction private func doneAction() {
        //create a basemap with the selected basemap index
        let basemap = basemaps[selectedBasemapIndex].copy() as! AGSBasemap
        
        //create an array of the selected operational layers
        let selectedLayers = selectedLayerIndices.map { layers[$0].copy() as! AGSLayer }
        
        delegate?.createOptionsViewController(self, didSelectBasemap: basemap, layers: selectedLayers)
    }
}
