//
// Copyright 2017 Esri.
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

protocol MapImageSublayersViewControllerDelegate: AnyObject {
    func mapImageSublayersViewController(_ controller: MapImageSublayersViewController, didCloseWith removedMapImageSublayers: [AGSArcGISMapImageSublayer])
}

class MapImageSublayersViewController: UITableViewController {
    var mapImageLayer: AGSArcGISMapImageLayer!
    var removedMapImageSublayers = [AGSArcGISMapImageSublayer]()
    
    weak var delegate: MapImageSublayersViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isEditing = true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.mapImageLayer?.mapImageSublayers.count ?? 0
        } else {
            return self.removedMapImageSublayers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapImageSublayerCell", for: indexPath)
        
        if indexPath.section == 0 {
            let sublayer = self.mapImageLayer.mapImageSublayers[indexPath.row] as AnyObject as! AGSArcGISMapImageSublayer
            cell.textLabel?.text = sublayer.name.isEmpty ? "Sublayer" : sublayer.name
        } else {
            let sublayer = self.removedMapImageSublayers[indexPath.row]
            cell.textLabel?.text = sublayer.name.isEmpty ? "Sublayer" : sublayer.name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Added" : "Removed"
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case 0:
            return .delete
        case 1:
            return .insert
        default:
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            tableView.beginUpdates()
            
            //remove row from table view
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            //remove sublayer from map image layer
            let sublayer = self.mapImageLayer.mapImageSublayers[indexPath.row] as AnyObject as! AGSArcGISMapImageSublayer
            
            self.mapImageLayer.mapImageSublayers.removeObject(at: indexPath.row)
            
            //add sublayer to the removed array
            self.removedMapImageSublayers.insert(sublayer, at: 0)
            
            let indexPath = IndexPath(row: 0, section: 1)
            
            //add row to the removed sublayer sources section
            tableView.insertRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        case .insert:
            tableView.beginUpdates()
            
            //remove row from table view
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            //remove sublayerSource from the removed array
            let sublayer = self.removedMapImageSublayers.remove(at: indexPath.row)
            
            //add sublayerSource to the added array
            self.mapImageLayer.mapImageSublayers.insert(sublayer, at: 0)
            
            let indexPath = IndexPath(row: 0, section: 0)
            
            //add row to the removed sublayer sources section
            tableView.insertRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sublayer = self.mapImageLayer.mapImageSublayers[sourceIndexPath.row]
        self.mapImageLayer.mapImageSublayers.removeObject(at: sourceIndexPath.row)
        self.mapImageLayer.mapImageSublayers.insert(sublayer, at: destinationIndexPath.row)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func doneAction() {
        //dismiss view controller
        self.dismiss(animated: true)
        
        //update the removed sublayers array on the delegate
        self.delegate?.mapImageSublayersViewController(self, didCloseWith: self.removedMapImageSublayers)
    }
}
