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

protocol MapImageSublayersVCDelegate:class {
    
    func mapImageSublayersVC(mapImageSublayersVC: MapImageSublayersVC, didCloseWith removedMapImageSublayers:[AGSArcGISMapImageSublayer])
}

class MapImageSublayersVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    
    var mapImageLayer:AGSArcGISMapImageLayer!
    var removedMapImageSublayers:[AGSArcGISMapImageSublayer]!
    
    weak var delegate:MapImageSublayersVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.isEditing = true
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.mapImageLayer?.mapImageSublayers.count ?? 0
        }
        else {
            return self.removedMapImageSublayers?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapImageSublayerCell", for: indexPath)
        
        if indexPath.section == 0 {
            let sublayer = self.mapImageLayer.mapImageSublayers[indexPath.row] as AnyObject as! AGSArcGISMapImageSublayer
            cell.textLabel?.text = sublayer.name.isEmpty ? "Sublayer" : sublayer.name
        }
        else {
            let sublayer = self.removedMapImageSublayers[indexPath.row]
            cell.textLabel?.text = sublayer.name.isEmpty ? "Sublayer" : sublayer.name
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Added" : "Removed (Tap to add)"
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
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
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let sublayer = self.mapImageLayer.mapImageSublayers[sourceIndexPath.row]
        self.mapImageLayer.mapImageSublayers.removeObject(at: sourceIndexPath.row)
        self.mapImageLayer.mapImageSublayers.insert(sublayer, at: destinationIndexPath.row)
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
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
        }
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func doneAction() {
        
        //dismiss view controller
        self.dismiss(animated: true, completion: nil)
        
        //update the removed sublayers array on the delegate
        self.delegate?.mapImageSublayersVC(mapImageSublayersVC: self, didCloseWith: self.removedMapImageSublayers)
    }

}
