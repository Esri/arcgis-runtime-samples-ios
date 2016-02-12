//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

class LegendInfo: NSObject {
    
    var name:String!
    var detail:String!
    var image:UIImage!
    
}

class LegendDataSource: NSObject, UITableViewDataSource {
    
    var layerTree:AGSMapContentsTree!
    var tableView:UITableView!
    var legendInfos:[LegendInfo]!
    
    init(layerTree tree:AGSMapContentsTree) {
        self.layerTree = tree
        super.init()
    }
    
    //MARK: -
    //MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.tableView = tableView
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.legendInfos = self.processLayerTreeStartingAt(self.layerTree.root)
        
        //Number of legend items we have
        return self.legendInfos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            cell!.selectionStyle = .None
        }
        
        // Set up the cell with the legend image, text, and detail
        let legendInfo = self.legendInfos[indexPath.row]
        cell?.detailTextLabel?.text = legendInfo.detail
        cell?.textLabel?.font = UIFont.systemFontOfSize(12.0)
        cell?.textLabel?.text = legendInfo.name
        cell?.imageView?.image = legendInfo.image
        
        return cell!
    }
    
    func processLayerTreeStartingAt(layerNode:AGSMapContentsLayerInfo) -> [LegendInfo] {
        var legendInfos = [LegendInfo]()
        if layerNode.legendItems != nil && layerNode.legendItems.count > 0 {
            for legendElement in layerNode.legendItems as! [AGSMapContentsLegendElement] {
                let li = LegendInfo()
                li.name = layerNode.layerName
                li.detail = legendElement.title
                li.image = legendElement.swatch
                legendInfos.append(li)
            }
        }
        
        for subLayerNode in layerNode.subLayers as! [AGSMapContentsLayerInfo] {
            legendInfos = legendInfos + self.processLayerTreeStartingAt(subLayerNode)
        }
        return legendInfos
    }
}
