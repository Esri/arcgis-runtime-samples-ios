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

class MILLegendTableViewController: UITableViewController {

    var operationalLayers:NSMutableArray!
    var legendInfosDict = [String:[AGSLegendInfo]]()
    private var orderArray:[AGSLayerContent]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.orderArray = [AGSLayerContent]()
        self.populateLegends(with: self.operationalLayers as AnyObject as! [AGSLayerContent])
    }
    
    func populateLegends(with layers:[AGSLayerContent]) {

        for i in 0...layers.count-1 {
            let layer = layers[i]

            if layer.subLayerContents.count > 0 {
                self.populateLegends(with: layer.subLayerContents)
            }
            else {
                //else if no sublayers fetch legend info
                self.orderArray.append(layer)
                layer.fetchLegendInfos(completion: { [weak self] (legendInfos:[AGSLegendInfo]?, error:Error?) -> Void in

                    if let error = error {
                        print(error)
                    }
                    else {
                        if let legendInfos = legendInfos {
                            self?.legendInfosDict[self!.hashString(for: layer)] = legendInfos
                            self?.tableView.reloadData()
                        }
                    }
                })
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return self.orderArray?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        let layer = self.orderArray[section]
        let legendInfos = self.legendInfosDict[self.hashString(for: layer)]
        return legendInfos?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let layerContent = self.orderArray[section]
        return self.nameForLayerContent(layerContent)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MILLegendCell", for: indexPath) 

        let layer = self.orderArray[indexPath.section]
        let legendInfos = self.legendInfosDict[self.hashString(for: layer)]!
        let legendInfo = legendInfos[indexPath.row]

        cell.textLabel?.text = legendInfo.name
        legendInfo.symbol?.createSwatch(completion: { (image: UIImage?, error: Error?) -> Void in
            if let updateCell = tableView.cellForRow(at: indexPath) {
                updateCell.imageView?.image = image
                updateCell.setNeedsLayout()
            }
        })
        
        cell.backgroundColor = .clear
        
        return cell
    }
    
    func geometryTypeForSymbol(_ symbol:AGSSymbol) -> AGSGeometryType {
        if symbol is AGSFillSymbol {
            return AGSGeometryType.polygon
        }
        else if symbol is AGSLineSymbol {
            return .polyline
        }
        else {
            return .point
        }
    }

    //MARK: - Helper functions
    
    func hashString (for obj: AnyObject) -> String {
        return String(UInt(bitPattern: ObjectIdentifier(obj)))
    }

    func nameForLayerContent(_ layerContent:AGSLayerContent) -> String {
        if let layer = layerContent as? AGSLayer {
            return layer.name
        }
        else {
            return (layerContent as! AGSArcGISSublayer).name
        }
    }
}
