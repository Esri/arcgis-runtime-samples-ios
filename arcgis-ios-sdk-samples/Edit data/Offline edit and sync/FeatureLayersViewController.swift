//
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

class FeatureLayersViewController: UITableViewController {
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    /// The layer infos to display in the table view.
    var featureLayerInfos = [AGSIDInfo]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    /// The layer infos selected in the table view.
    var selectedLayerInfos: [AGSIDInfo] {
        if let indexPaths = tableView.indexPathsForSelectedRows {
            return indexPaths.map { featureLayerInfos[$0.row] }
        } else {
            return []
        }
    }
    
    var onCompletion: (([Int]) -> Void)?
    
    private func updateDoneButtonEnabledState() {
        doneButton?.isEnabled = !selectedLayerInfos.isEmpty
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featureLayerInfos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeatureLayerCell", for: indexPath)
        
        let layerInfo = featureLayerInfos[indexPath.row]
        cell.textLabel?.text = layerInfo.name
        if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.contains(indexPath) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        updateDoneButtonEnabledState()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        updateDoneButtonEnabledState()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        // get selected layer ids
        let selectedLayerIds = selectedLayerInfos.map { $0.id }
        
        // run the completion handler
        onCompletion?(selectedLayerIds)
        
        dismiss(animated: true)
    }
}
