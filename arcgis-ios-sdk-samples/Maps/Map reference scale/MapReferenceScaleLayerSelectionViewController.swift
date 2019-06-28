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

/// The delegate of a `MapReferenceScaleLayerSelectionViewController`.
protocol MapReferenceScaleLayerSelectionViewControllerDelegate: AnyObject {
    /// Tells the delegate that the given layer was selected.
    ///
    /// - Parameters:
    ///   - controller: The controller sending the message.
    ///   - layer: The layer that was selected.
    func mapReferenceScaleLayerSelectionViewController(_ controller: MapReferenceScaleLayerSelectionViewController, didSelect layer: AGSLayer)
    /// Tells the delegate the the given layer was deselected.
    ///
    /// - Parameters:
    ///   - controller: The controller sending the message.
    ///   - layer: The layer that was deselected.
    func mapReferenceScaleLayerSelectionViewController(_ controller: MapReferenceScaleLayerSelectionViewController, didDeselect layer: AGSLayer)
}

/// A view controller that manages an interface for selecting layers from a
/// list.
class MapReferenceScaleLayerSelectionViewController: UITableViewController {
    /// The layers shown in the table view.
    var layers = [AGSLayer]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    /// The delegate of the view controller.
    weak var delegate: MapReferenceScaleLayerSelectionViewControllerDelegate?
    
    /// The index paths of the selected layers.
    private var indexPathsForSelectedRows = Set<IndexPath>()
    
    /// Selects the given layer in the list.
    ///
    /// - Parameter layer: A layer.
    func selectLayer(_ layer: AGSLayer) {
        guard let row = layers.firstIndex(of: layer) else { return }
        let indexPath = IndexPath(row: row, section: 0)
        indexPathsForSelectedRows.insert(indexPath)
    }
    
    /// Returns the appropriate accessory type for the cell at the given index
    /// path.
    ///
    /// - Parameter indexPath: An index path.
    /// - Returns: An accessory type. If the corresponding layer is selected,
    /// the type is `checkmark`. Otherwise the type is `none`.
    private func accessoryTypeForCell(at indexPath: IndexPath) -> UITableViewCell.AccessoryType {
        return indexPathsForSelectedRows.contains(indexPath) ? .checkmark : .none
    }
}

extension MapReferenceScaleLayerSelectionViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return layers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell", for: indexPath)
        cell.textLabel?.text = layers[indexPath.row].name
        cell.accessoryType = accessoryTypeForCell(at: indexPath)
        return cell
    }
}

extension MapReferenceScaleLayerSelectionViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let layer = layers[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        if indexPathsForSelectedRows.contains(indexPath) {
            indexPathsForSelectedRows.remove(indexPath)
            cell?.accessoryType = accessoryTypeForCell(at: indexPath)
            delegate?.mapReferenceScaleLayerSelectionViewController(self, didDeselect: layer)
        } else {
            indexPathsForSelectedRows.insert(indexPath)
            cell?.accessoryType = accessoryTypeForCell(at: indexPath)
            delegate?.mapReferenceScaleLayerSelectionViewController(self, didSelect: layer)
        }
    }
}
