// Copyright 2021 Esri
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

class DisplayContentUtilityNetworkTableViewController: UITableViewController {
    var legendInfos = [AGSLegendInfo]()
    var contentSwatches = KeyValuePairs<String, UIImage>()
    var images = [(String, UIImage)]()
   
    // Set the number of rows.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return legendInfos.count + contentSwatches.count
    }
    
    // Set the number of sections.
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DisplayContentLegendCell", for: indexPath)
        // Add the container view swatches to the legend after the feature layer legend information.
//        if indexPath.row >= legendInfos.count {
//            let contentSwatch = indexPath.row - legendInfos.count
//            cell.textLabel?.text = contentSwatches[contentSwatch].key
//            cell.imageView?.image = contentSwatches[contentSwatch].value
//            cell.setNeedsLayout()
//        } else {
//            // Add the information provided by the feature layers to the legend.
//            let legendInfo = legendInfos[indexPath.row]
//            cell.textLabel?.text = legendInfo.name
//            legendInfo.symbol?.createSwatch { (image, _) in
//                cell.imageView?.image = image
//                cell.setNeedsLayout()
//            }
//        }
        cell.textLabel?.text = images[indexPath.row].0
        cell.imageView?.image = images[indexPath.row].1
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
