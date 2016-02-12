/*
Copyright 2015 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import ArcGIS

protocol OptionsDelegate:class {
    func optionsViewController(optionsViewController:OptionsViewController, didSelectOption option:AGSLayerInfo)
}

class OptionsViewController: UITableViewController {
    
    var options:[AGSLayerInfo]! {
        didSet {
            //reload the tableview every time options is assigned a value
            self.tableView.reloadData()
        }
    }
    weak var delegate:OptionsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //change background color to transparent
        self.tableView.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if self.options != nil {
            return self.options.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reusableIdentifier = "OptionCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reusableIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: reusableIdentifier)
        }
        let layerInfo = self.options[indexPath.row]
        cell?.textLabel?.text = layerInfo.name
        cell?.backgroundColor = UIColor.clearColor()
        
        return cell!
    }
    
    //MARK:- table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //notify the delegate about the selection
        let layerInfo = self.options[indexPath.row]
        self.delegate?.optionsViewController(self, didSelectOption:layerInfo)
    }

}
