// Copyright 2015 Esri.
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

    var operationalLayers:AGSList!
    var legendInfosDict = [String:[AGSLegendInfo]]()
    private var orderArray:[AGSLayerContent]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.orderArray = [AGSLayerContent]()
        self.populateLegends(self.operationalLayers)
    }
    
    func populateLegends(layers:AGSList) {

        for i in 0...layers.count-1 {
            let layer = layers[UInt(i)] as! AGSLayerContent

            if let sublayers = layer.sublayers where sublayers.count > 0 {
                self.populateLegends(sublayers)
            }
            else {
                //else if no sublayers fetch legend info
                self.orderArray.append(layer)
                layer.fetchLegendInfosWithCompletion({ [weak self] (legendInfos:[AGSLegendInfo]?, error:NSError?) -> Void in
                    if let error = error {
                        print(error)
                    }
                    else {
                        if let legendInfos = legendInfos {
                            self?.legendInfosDict[self!.hashString(layer)] = legendInfos
                            self?.tableView.reloadData()
                        }
                    }
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return self.orderArray?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        let layer = self.orderArray[section]
        let legendInfos = self.legendInfosDict[self.hashString(layer)]
        return legendInfos?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let layerContent = self.orderArray[section]
        return self.nameForLayerContent(layerContent)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MILLegendCell", forIndexPath: indexPath) 

        let layer = self.orderArray[indexPath.section]
        let legendInfos = self.legendInfosDict[self.hashString(layer)]!
        let legendInfo = legendInfos[indexPath.row]

        cell.textLabel?.text = legendInfo.name
        
        if let markerSymbol = legendInfo.symbol as? AGSPictureMarkerSymbol {
            cell.imageView?.image = markerSymbol.image
        }
        else {
            print("symbol is not picture marker symbol")
        }
        
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }

    //MARK: - Helper functions
    
    func hashString (obj: AnyObject) -> String {
        return String(ObjectIdentifier(obj).uintValue)
    }

    func nameForLayerContent(layerContent:AGSLayerContent) -> String {
        if let layer = layerContent as? AGSLayer {
            return layer.name!
        }
        else {
            return (layerContent as! AGSArcGISSublayer).name!
        }
    }
}
