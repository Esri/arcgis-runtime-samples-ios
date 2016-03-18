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

class FeatureLayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    
    var featureLayerInfos:[AGSArcGISFeatureLayerInfo]! {
        didSet {
            self.tableView?.reloadData()
        }
    }
    var selectedLayerIds = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.featureLayerInfos?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FeatureLayerCell")!
        
        let layerInfo = self.featureLayerInfos[indexPath.row]
        cell.textLabel?.text = layerInfo.serviceLayerName
        
        //accessory view
        if self.selectedLayerIds.contains(layerInfo.serviceLayerID) {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let layerInfo = self.featureLayerInfos[indexPath.row]
        
        if let index = self.selectedLayerIds.indexOf(layerInfo.serviceLayerID) {
            self.selectedLayerIds.removeAtIndex(index)
        }
        else {
            self.selectedLayerIds.append(layerInfo.serviceLayerID)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
}
