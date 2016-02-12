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

import UIKit

protocol OptionsViewControllerDelegate:class  {
    
    //delegate used to notify that an option was selected
    func optionsViewController(optionsViewController: OptionsViewController, didSelectIndex index:(NSInteger), forTextField textField:(UITextField))
}

class OptionsViewController: UITableViewController {

    //array to store the list of options as NSString
    var options:[String]! {
        didSet {
            self.tableView.reloadData()
        }
    }
    //UITextField for which the options need to be displayed
    var textField:UITextField!
    
    weak var delegate:OptionsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //clear table background color
        self.tableView.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - table view datasource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.options != nil {
            return self.options.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = "OptionCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: reuseIdentifier)
        }
        let option = self.options[indexPath.row]
        cell!.textLabel!.text = option
        //clear cell background color
        cell!.backgroundColor = UIColor.clearColor()
        return cell!
    }
    
    //MARK: - tableview delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //notify the delegate
        self.delegate?.optionsViewController(self, didSelectIndex:indexPath.row, forTextField:self.textField)
    }
}
