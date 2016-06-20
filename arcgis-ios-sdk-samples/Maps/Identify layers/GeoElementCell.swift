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

class GeoElementCell: UICollectionViewCell, UITableViewDataSource {
    
    @IBOutlet var tableView:UITableView!
    @IBOutlet var headerLabel:UILabel!
    
    var geoElement:AGSGeoElement! {
        didSet {
            self.tableView.reloadData()
            
            //set header label
            self.headerLabel.text = geoElement.layerName
            
            //reset table view contentoffset
            self.tableView.contentOffset.y = 0
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.geoElement?.attributes.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AttributesCell")!
        //set the key name as the text label
        cell.textLabel?.text = Array(self.geoElement.attributes.keys)[indexPath.row]
        
        //set the value as the detail text
        //check for strings
        let value = Array(self.geoElement.attributes.values)[indexPath.row]
        if value is String {
            cell.detailTextLabel?.text = value as? String
        }
        else {
            cell.detailTextLabel?.text = "\(value)"
        }
        
        return cell
    }
}
