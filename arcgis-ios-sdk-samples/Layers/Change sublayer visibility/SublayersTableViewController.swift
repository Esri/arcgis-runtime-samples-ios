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

class SublayersTableViewController: UITableViewController {

    //list of sublayers
    var sublayers:NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sublayers?.count ?? 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SublayerCell")!
        cell.backgroundColor = UIColor.clearColor()
        
        let sublayer = self.sublayers[indexPath.row] as! AGSArcGISMapImageSublayer
        cell.textLabel?.text = sublayer.name
        
        //accessory switch
        let visibilitySwitch = UISwitch(frame: CGRectZero)
        visibilitySwitch.tag = indexPath.row
        visibilitySwitch.on = sublayer.visible
        visibilitySwitch.addTarget(self, action: #selector(SublayersTableViewController.switchChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        cell.accessoryView = visibilitySwitch
        return cell
    }
    
    func switchChanged(sender:UISwitch) {
        let index = sender.tag
        //change the visiblity
        let sublayer = self.sublayers[index] as! AGSArcGISMapImageSublayer
        sublayer.visible = sender.on
    }
}
