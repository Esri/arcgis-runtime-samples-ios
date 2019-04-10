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
    /// The sublayers to be displayed in the table view.
    var sublayers = [AGSArcGISMapImageSublayer]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    private var tableViewContentSizeObservation: NSKeyValueObservation?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] (tableView, _) in
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: tableView.contentSize.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableViewContentSizeObservation = nil
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sublayers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sublayer = sublayers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SublayerCell", for: indexPath)
        cell.textLabel?.text = sublayer.name
        //accessory switch
        let visibilitySwitch = UISwitch(frame: .zero)
        visibilitySwitch.tag = indexPath.row
        visibilitySwitch.isOn = sublayer.isVisible
        visibilitySwitch.addTarget(self, action: #selector(SublayersTableViewController.switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = visibilitySwitch
        return cell
    }
    
    @objc
    func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        //change the visiblity
        let sublayer = self.sublayers[index]
        sublayer.isVisible = sender.isOn
    }
}
