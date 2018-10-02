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

class DisplayKMLViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    /// A model for our three data sources.
    enum KMLDataSource: String, CaseIterable {
        case url, localFile, portalItem
    }
    
    // the source currently loaded in the map
    private var displayedSource: KMLDataSource = .url{
        didSet{
            // load the map contents based on the specified source
            switch displayedSource{
            case .url:
                changeSourceToURL()
            case .localFile:
                changeSourceToLocalFile()
            case .portalItem:
                changeSourceToPortalItem()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate a map with a dark gray basemap centered on the United States
        let map = AGSMap(basemapType: .darkGrayCanvasVector, latitude: 39, longitude: -98, levelOfDetail: 4)
        // Display the map in the map view
        mapView.map = map
        
        // Set the initial KML source
        displayedSource = .url
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayKMLViewController"]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // if we're opening the table of data sources
        if let sourceTableViewController = segue.destination as? UITableViewController {
            
            // set the popover height
            sourceTableViewController.preferredContentSize.height = 135
            
            // show the selected source in the table with a checkmark
            for i in 0..<sourceTableViewController.tableView.numberOfRows(inSection: 0){
                if let cell = sourceTableViewController.tableView.cellForRow(at: IndexPath(row: i, section: 0)),
                    displayedSource == KMLDataSource(rawValue: cell.reuseIdentifier!) {
                    cell.accessoryType = .checkmark
                    break
                }
            }
            
            // set the delgates
            sourceTableViewController.tableView.delegate = self
            sourceTableViewController.popoverPresentationController?.delegate = self
        }
    }
    
    //MARK: - KML Loading
    
    private func display(kmlLayer: AGSKMLLayer){
        
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

            if let self = self,
                let error = error {
                // Display the error if one occurred
                let alertController = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alertController, animated: true, completion: nil)
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

extension DisplayKMLViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get the selected cell
        let selectedCell = tableView.cellForRow(at: indexPath)!
        
        // remove the existing checkmark
        for i in 0..<tableView.numberOfRows(inSection: 0){
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)),
                cell.accessoryType == .checkmark{
                cell.accessoryType = .none
                break
            }
        }
        // add a checkmark to the selected cell
        selectedCell.accessoryType = .checkmark
        
        // close the popover
        presentedViewController?.dismiss(animated: true)
        
        // change the displayed KML source based on the selected cell
        displayedSource = KMLDataSource(rawValue: selectedCell.reuseIdentifier!)!
    }
}

extension DisplayKMLViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // prevent the popover from displaying fullscreen in narrow contexts
        return .none
    }
}
