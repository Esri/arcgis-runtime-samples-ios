// Copyright 2018 Esri.
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

import ArcGIS

/// A model for our three data sources.
private enum KMLDataSource: Int {
    case url, localFile, portalItem
}

class DisplayKMLViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    /// The source currently loaded in the map.
    private var displayedSource: KMLDataSource = .url {
        didSet{
            updateMapForDisplayedSource()
        }
    }
    
    /// Loads the map contents based on the specified source.
    private func updateMapForDisplayedSource() {
        switch displayedSource{
        case .url:
            changeSourceToURL()
        case .localFile:
            changeSourceToLocalFile()
        case .portalItem:
            changeSourceToPortalItem()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate a map with a dark gray basemap centered on the United States
        let map = AGSMap(basemapType: .darkGrayCanvasVector, latitude: 39, longitude: -98, levelOfDetail: 4)
        // Display the map in the map view
        mapView.map = map
        
        // Show the initial KML source
        updateMapForDisplayedSource()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayKMLViewController"]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // if we're opening the table of data sources
        if let sourceTableViewController = segue.destination as? DisplayKMLDataSourcesTableViewController {
            
            // set the popover height
            sourceTableViewController.preferredContentSize.height = 135
            
            // set the popover delgate
            sourceTableViewController.popoverPresentationController?.delegate = self
            
            // setup the view controller
            sourceTableViewController.initialSelectedIndex = displayedSource.rawValue
            sourceTableViewController.selectionHandler = { [weak self] (dataSource) in
                guard let self = self else{
                    return
                }
                // close the popover
                self.presentedViewController?.dismiss(animated: true)
                // set the displayed source based on the selection
                self.displayedSource = dataSource
            }
        }
    }
    
    //MARK: - KML Loading
    
    private func display(kmlLayer: AGSKMLLayer) {
        
        // Clear the existing layers from the map
        mapView.map?.operationalLayers.removeAllObjects()
        // Add the KML layer to the map
        mapView.map?.operationalLayers.add(kmlLayer)
        
        // Show the progress indicator
        SVProgressHUD.show(withStatus: "Loading KML Layer")
        
        // This load call is not required, but it allows for error
        // feedback and progress indication
        kmlLayer.load {[weak self] (error) in
            
            // Close the progress indicator
            SVProgressHUD.dismiss()

            if let error = error {
                self?.presentAlert(error: error)
            }
        }
        
    }
    
    private func changeSourceToURL() {
        /// A URL of a remote KML file
        let kmlDatasetURL = URL(string: "https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx.kml")!
        let kmlDataset = AGSKMLDataset(url: kmlDatasetURL)
        /// A KML layer created from a remote KML file
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        display(kmlLayer: kmlLayer)
    }
    
    private func changeSourceToLocalFile() {
        /// A dataset created by referencing the name of a KML file in the app bundle
        let kmlDataset = AGSKMLDataset(name: "US_State_Capitals")
        /// A KML layer created from a local KML file
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        display(kmlLayer: kmlLayer)
    }
    
    private func changeSourceToPortalItem() {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        /// A remote KML portal item
        let portalItem = AGSPortalItem(portal: portal, itemID: "9fe0b1bfdcd64c83bd77ea0452c76253")
        /// A KML layer created from an ArcGIS Online portal item
        let kmlLayer = AGSKMLLayer(item: portalItem)
        display(kmlLayer: kmlLayer)
    }
    
}

extension DisplayKMLViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // prevent the popover from displaying fullscreen in narrow contexts
        return .none
    }
}

class DisplayKMLDataSourcesTableViewController: UITableViewController {
    
    fileprivate var initialSelectedIndex = 0
    fileprivate var selectionHandler: ((KMLDataSource)->Void)?
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath.row == initialSelectedIndex{
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // get the newly selected cell
        guard let selectedCell = tableView.cellForRow(at: indexPath),
            let displayedSource = KMLDataSource(rawValue: indexPath.row) else {
            return
        }
        
        // add a checkmark to the selected cell
        selectedCell.accessoryType = .checkmark
        
        // change the displayed KML source based on the selected cell
        selectionHandler?(displayedSource)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // remove the checkmark
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
}
