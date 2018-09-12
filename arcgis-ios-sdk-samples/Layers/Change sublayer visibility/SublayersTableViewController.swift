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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sublayers?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SublayerCell", for: indexPath)
        cell.backgroundColor = .clear
        
        let sublayer = self.sublayers[indexPath.row] as! AGSArcGISMapImageSublayer
        cell.textLabel?.text = sublayer.name
        
        //accessory switch
        let visibilitySwitch = UISwitch(frame: CGRect.zero)
        visibilitySwitch.tag = indexPath.row
        visibilitySwitch.isOn = sublayer.isVisible
        visibilitySwitch.addTarget(self, action: #selector(SublayersTableViewController.switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = visibilitySwitch
        return cell
    }
    
    @objc func switchChanged(_ sender:UISwitch) {
        let index = sender.tag
        //change the visiblity
        let sublayer = self.sublayers[index] as! AGSArcGISMapImageSublayer
        sublayer.isVisible = sender.isOn
    }
}
