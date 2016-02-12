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

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //results are the attributes of the result of the geocode operation
    var results:[NSObject:AnyObject]!
    var tableView:UITableView!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    @IBAction func done(sender:AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: -
    //MARK: - Table view methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Customize the number of rows in the table view.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //if results is not nil and we have results, return that number
        return self.results.count ?? 0
    }
    
    // Customize the appearance of table view cells.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier)
        }
        
        // Set up the cell...
        
        //text is the key at the given indexPath
        let keyAtIndexPath = Array(self.results.keys)[indexPath.row]
        cell?.textLabel?.text = keyAtIndexPath as? String
        
        //detail text is the value associated with the key above
        if let detailValue: AnyObject? = self.results[keyAtIndexPath] {
            
            //figure out if the value is a NSDecimalNumber or NSString
            if detailValue is String {
                //value is a NSString, just set it
                cell?.detailTextLabel?.text = detailValue as? String
            }
            else if detailValue is NSDecimalNumber {
                //value is a NSDecimalNumber, format the result as a double
                cell?.detailTextLabel?.text = String(format: "%0.0f", detailValue as! NSDecimalNumber)
            }
            else {
                //not a NSDecimalNumber or a NSString,
                cell?.detailTextLabel?.text = "N/A"
            }
        }
        
        return cell!
    }

}
