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

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView:UITableView!
    var results:[NSObject: AnyObject]!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return self.results.count
    }

     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "ResultsCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!

        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
        }
        
        //text is the key at the given indexPath
        let keyAtIndexPath = Array(self.results.keys)[indexPath.row]
        cell.textLabel?.text = keyAtIndexPath as? String
        
        //detail text is the value associated with the key above
        if let detailValue: AnyObject = self.results[keyAtIndexPath] {
        
            //figure out if the value is a NSDecimalNumber or NSString
            if detailValue is NSString {
                //value is a NSString, just set it
                cell.detailTextLabel?.text = detailValue as? String
            }
            else if detailValue is NSDecimalNumber {
                //value is a NSDecimalNumber, format the result as a double
                cell.detailTextLabel?.text = "\((detailValue as NSDecimalNumber).doubleValue)"
            }
            else {
                //not a NSDecimalNumber or a NSString,
                cell.detailTextLabel?.text = "N/A"
            }
        }
        return cell
    }

    @IBAction func done(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
