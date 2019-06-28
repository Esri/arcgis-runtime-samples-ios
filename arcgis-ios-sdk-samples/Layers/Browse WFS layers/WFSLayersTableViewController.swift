// Copyright 2019 Esri.
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

class WFSLayersTableViewController: UITableViewController {
    // Every layer info that could be used to create a WFSFeatureTable
    var allLayerInfos: [AGSWFSLayerInfo] = []
    
    // MapView to display the map with WFS features
    var mapView: AGSMapView?
    
    // Layer Info for the layer that is currently drawn on map view
    var selectedLayerInfo: AGSWFSLayerInfo?
    
    private var shouldSwapCoordinateOrder = false
    private var lastQuery: AGSCancelable?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedLayerInfo = selectedLayerInfo, let selectedRow = allLayerInfos.firstIndex(of: selectedLayerInfo) {
            let selectedIndexPath = IndexPath(row: selectedRow, section: 0)
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .middle)
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .checkmark
        }
    }
    
    // A convenience type for the table view sections.
    private enum Section: Int {
        case operational, swapCoordinateOrder
        
        var label: String {
            switch self {
            case .operational:
                return "Operational Layers"
            case .swapCoordinateOrder:
                return "Coordinate Order"
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.label
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .operational:
            return allLayerInfos.count
        case .swapCoordinateOrder:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .operational:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell", for: indexPath)
            let layerInfo = allLayerInfos[indexPath.row]
            cell.textLabel?.text = layerInfo.title
            cell.accessoryType = (tableView.indexPathForSelectedRow == indexPath) ? .checkmark : .none
            return cell
        case .swapCoordinateOrder:
            let cell: SettingsTableViewCell = (tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as? SettingsTableViewCell)!
            cell.swapCoordinateOrderSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            return cell
        }
    }
    
    @objc
    func switchChanged(_ swapSwitch: UISwitch) {
        // Keep track of whether coordinate order should be swapped
        self.shouldSwapCoordinateOrder = swapSwitch.isOn
        
        // Check if there is a layer selected
        if tableView.indexPathForSelectedRow != nil {
                // Query for features taking into account the updated swap order, and display the layer
                displaySelectedLayer()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath), indexPath.section == 0  else {
            return
        }
        
        // add a checkmark to the selected cell
        selectedCell.accessoryType = .checkmark
        
        if self.selectedLayerInfo != allLayerInfos[indexPath.row] {
            // Get the selected layer info.
            self.selectedLayerInfo = allLayerInfos[indexPath.row]
    
            // Query for features and display the selected layer
            displaySelectedLayer()
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
    }
    
    // MARK: - Helper Method
    
    func displaySelectedLayer() {
        // Check if selected layer info is non-nil
        guard let selectedLayerInfo = self.selectedLayerInfo else {
            return
        }
        
        // Create a WFS feature table with the layer info
        let wfsFeatureTable = AGSWFSFeatureTable(layerInfo: selectedLayerInfo)
        
        // Set the feature request mode to manual - only manual is supported at v100.5.
        // In this mode, you must manually populate the table - panning and zooming won't request features automatically.
        wfsFeatureTable.featureRequestMode = .manualCache
        
        // Set the axis order based on the UI. It is by default false.
        wfsFeatureTable.axisOrder = self.shouldSwapCoordinateOrder ? .swap : .noSwap
        
        // If there is an existing query request, cancel it
        if let lastQuery = self.lastQuery {
            lastQuery.cancel()
        }
        // Create query parameters
        let params = AGSQueryParameters()
        params.whereClause = "1=1"
        
        // Show progress
        SVProgressHUD.show(withStatus: "Querying")
        
        // Populate features based on query
        self.lastQuery = wfsFeatureTable.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
            guard let self = self else { return }
            
            // Check and get results
            if let result = result, let mapView = self.mapView {
                // The resulting features should be displayed on the map
                // Print the count of features
                print("Populated \(result.featureEnumerator().allObjects.count) features.")
                
                // Create a feature layer from the WFS table.
                let wfsFeatureLayer = AGSFeatureLayer(featureTable: wfsFeatureTable)
                
                // Choose a renderer for the layer
                wfsFeatureLayer.renderer = AGSSimpleRenderer.random(wfsFeatureTable)
                
                // Replace map's operational layer
                mapView.map?.operationalLayers.setArray([wfsFeatureLayer])
                
                // Zoom to the extent of the layer
                mapView.setViewpointGeometry(selectedLayerInfo.extent!, padding: 50.0)
            }
                // Check for error. If it's a user canceled error, do nothing.
                // Otherwise, display an alert.
            else if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                } else {
                    return
                }
            }
            // Hide Progress
            SVProgressHUD.dismiss()
        }
    }
}

private extension AGSSimpleRenderer {
    /// Creates a renderer appropriate for the geometry type of the table,
    /// and symbolizes the renderer with a random color
    ///
    /// - Returns: A new `AGSSimpleRenderer` object.
    static func random(_ table: AGSFeatureTable) -> AGSSimpleRenderer? {
        switch table.geometryType {
        case .point, .multipoint:
            let simpleMarkerSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .random(), size: 4.0)
            return AGSSimpleRenderer(symbol: simpleMarkerSymbol)
        case .polyline:
            let simpleLineSymbol = AGSSimpleLineSymbol(style: .solid, color: .random(), width: 1.0)
            return AGSSimpleRenderer(symbol: simpleLineSymbol)
        case .polygon, .envelope:
            let simpleFillSymbol = AGSSimpleFillSymbol(style: .solid, color: .random(), outline: nil)
            return AGSSimpleRenderer(symbol: simpleFillSymbol)
        default:
            return nil
        }
    }
}

private extension UIColor {
    /// Creates a random color whose red, green, and blue values are in the
    /// range `0...1` and whose alpha value is `1`.
    ///
    /// - Returns: A new `UIColor` object.
    static func random() -> UIColor {
        let range: ClosedRange<CGFloat> = 0...1
        return UIColor(red: .random(in: range), green: .random(in: range), blue: .random(in: range), alpha: 1)
    }
}

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var swapCoordinateOrderSwitch: UISwitch!
}
