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

protocol CreateOptionsVCDelegate: AnyObject {
    func createOptionsViewController(_ createOptionsViewController:CreateOptionsViewController, didSelectBasemap basemap:AGSBasemap, layers:[AGSLayer]?)
}

class CreateOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private weak var tableView:UITableView!
    
    private var basemaps: [AGSBasemap] = [.streets(), .imagery(), .topographic(), .oceans()]
    private var layers = [AGSLayer]()
    
    private var layerURLs = ["https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer",
        "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer"]
    
    private var selectedBasemapIndex:Int!
    private var selectedLayersIndex = [Int]()
    
    
    weak var delegate:CreateOptionsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //populate layers array
        for urlString in self.layerURLs {
            let layer = AGSArcGISMapImageLayer(url: URL(string: urlString)!)
            self.layers.append(layer)
        }
        
        //self sizing cells
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        
    }
    
    func resetTableView() {
        self.selectedBasemapIndex = nil
        self.selectedLayersIndex = [Int]()
        self.tableView.reloadData()
    }

    //MARK: - table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? self.basemaps.count : self.layers.count
    }
    
    //MARK: - table view delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "CreateBasemapCell", for: indexPath)
            let basemap = self.basemaps[indexPath.row]
            cell.textLabel?.text = basemap.name
            
            //accesory view
            if let index = self.selectedBasemapIndex , index == indexPath.row {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "CreateLayerCell", for: indexPath)
            let layer = self.layers[indexPath.row]
            cell.textLabel?.text = layer.name
            //accessory view
            if self.selectedLayersIndex.contains(indexPath.row) {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var indexPathArray = [IndexPath]()
        
        if indexPath.section == 0 {
            if let previousSelectionIndex = self.selectedBasemapIndex {
                //create a IndexPath for the previously selected index
                let previousSelectionIndexPath = IndexPath(row: previousSelectionIndex, section: 0)
                indexPathArray.append(previousSelectionIndexPath)
            }
            self.selectedBasemapIndex = indexPath.row
        }
        else {
            //check if already selected
            if self.selectedLayersIndex.contains(indexPath.row) {
                //remove the selection
                self.selectedLayersIndex.remove(at: self.selectedLayersIndex.index(of: indexPath.row)!)
            }
            else {
                self.selectedLayersIndex.append(indexPath.row)
            }
        }
        indexPathArray.append(indexPath)
        //reload selected cells instead of the whole table view
        tableView.reloadRows(at: indexPathArray, with: .none)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Choose a basemap" : "Add operational layers"
    }

    //MARK: - Actions
    
    @IBAction private func doneAction() {
        if self.selectedBasemapIndex == nil {
            presentAlert(message: "Please select at least a basemap")
            return
        }

        //create a basemap with the selected basemap index
        let basemap = self.basemaps[self.selectedBasemapIndex].copy() as! AGSBasemap
        
        //create an array of the selected operational layers
        var layers = [AGSLayer]()
        for index in self.selectedLayersIndex {
            let layer = self.layers[index].copy() as! AGSLayer
            layers.append(layer)
        }
        
        self.delegate?.createOptionsViewController(self, didSelectBasemap: basemap, layers: layers.count > 0 ? layers : nil)
    }

}
