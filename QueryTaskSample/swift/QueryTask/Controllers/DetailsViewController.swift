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

class DetailsViewController: UITableViewController {
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    var fieldAliases:[NSObject:AnyObject]! {
        didSet {
            self.aliases = Array(fieldAliases.keys) as [NSObject]
        }
    }
    var displayFieldName:String!
    var feature:AGSGraphic! {
        didSet {
            self.title = feature.attributeAsStringForKey(self.displayFieldName)
            
            self.tableView.reloadData()
        }
    }
        
    var aliases:[NSObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view methods
    
    //one section in this table
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    //the section in the table is as large as the number of attributes the feature has
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.aliases.count ?? 0
    }
    
    //called by table view when it needs to draw one of its rows
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //static instance to represent a single kind of cell. Used if the table has cells formatted differently
        let kDetailsViewControllerCellIdentifier = "DetailsViewControllerCellIdentifier"
        
        //as cells roll off screen get the reusable cell, if we can't create a new one
        var cell = tableView.dequeueReusableCellWithIdentifier(kDetailsViewControllerCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: kDetailsViewControllerCellIdentifier)
        }
        
        //extract the attribute and its value and display both in the cell
        let key:NSObject = self.aliases[indexPath.row] as NSObject
        cell?.textLabel?.text = self.fieldAliases[key] as? String
        cell?.detailTextLabel?.text = "\(self.feature.attributeAsStringForKey(key as! String))"
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Navigation logic may go here. Create and push another view controller.

    }
}
