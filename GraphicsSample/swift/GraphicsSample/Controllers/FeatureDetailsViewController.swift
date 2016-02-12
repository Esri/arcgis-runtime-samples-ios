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

class FeatureDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var detailsTable:UITableView!
    
    var feature:AGSGraphic! {
        didSet {
            let theDict = self.feature.allAttributes()
            let allKeys = Array(theDict.keys)
            self.keys = allKeys as! [String]
            self.aliases = self.keys
        }
    }
    var displayFieldName:String!
    var keys:[String]!
    var aliases:[String]!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = self.feature.attributeAsStringForKey(self.displayFieldName)
        self.detailsTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setFieldAliases(fa:[NSObject:AnyObject]) {
        if self.keys != nil {
            
            self.aliases = [String]()
            for key in self.keys {
                let alias = fa[key] as! String
                self.aliases.append(alias)
            }
        }
    }

    
    //MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.keys.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "FeatureDetailsViewControllerCellIdentifier"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            
            cell = UITableViewCell(style: .Value1, reuseIdentifier: cellIdentifier)
        }
        
        //extract the attribute and its value and display both in the cell
        cell?.textLabel?.text = self.aliases[indexPath.row]
        
        let key = self.keys[indexPath.row]
        
        cell?.detailTextLabel?.text = "\(self.feature.attributeAsStringForKey(key))"
        
        return cell!
    }
    
    //MARK: - actions
    
    @IBAction func done(sender:AnyObject) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
}
