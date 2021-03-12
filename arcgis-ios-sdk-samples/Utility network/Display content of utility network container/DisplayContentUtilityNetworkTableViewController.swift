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
    var boundingBoxSwatch: UIImage?
    var attachmentSwatch: UIImage?
    var connectivitySwatch: UIImage?
    var contentSwatchesDict = KeyValuePairs<String, UIImage>()
    
    func makeDictionary() -> KeyValuePairs<String, UIImage> {
        if let boundingBoxSwatch = boundingBoxSwatch, let attachmentSwatch = attachmentSwatch, let connectivitySwatch = connectivitySwatch {
            return [
                "Bounding box": boundingBoxSwatch,
                "Attachment": attachmentSwatch,
                "Connectivity": connectivitySwatch
            ]
        }
        return [:]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contentSwatchesDict = makeDictionary()
        return legendInfos.count + contentSwatchesDict.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DisplayContentLegendCell", for: indexPath)
        if indexPath.row >= legendInfos.count {
            let contentSwatch = indexPath.row - legendInfos.count
            cell.textLabel?.text = contentSwatchesDict[contentSwatch].key
            cell.imageView?.image = contentSwatchesDict[contentSwatch].value
            cell.setNeedsLayout()
        } else {
            let legendInfo = legendInfos[indexPath.row]
            cell.textLabel?.text = legendInfo.name
            legendInfo.symbol?.createSwatch { (image, _) in
                cell.imageView?.image = image
                cell.setNeedsLayout()
            }
        }
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
