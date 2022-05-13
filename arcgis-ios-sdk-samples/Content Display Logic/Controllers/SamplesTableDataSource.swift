//
//  ContentTableDataSource.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Vivian Quach on 5/12/22.
//  Copyright © 2022 Esri. All rights reserved.
//

import UIKit


class SamplesTableDataSource: NSObject, UITableViewDataSource  {
    var displayedSamples = [Sample]()
    private var expandedRowIndexPaths: Set<IndexPath> = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedSamples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sample = displayedSamples[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentTableCell", for: indexPath) as! ContentTableCell
        cell.titleLabel.text = sample.name
        cell.detailLabel.text = sample.description
        cell.isExpanded = expandedRowIndexPaths.contains(indexPath)
        return cell
    }
    
}
