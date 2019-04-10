//
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

class RouteParametersViewController: UITableViewController {
    @IBOutlet var findBestSequenceSwitch: UISwitch?
    @IBOutlet var preserveFirstStopSwitch: UISwitch?
    @IBOutlet var preserveLastStopSwitch: UISwitch?
    
    var routeParameters: AGSRouteParameters? {
        didSet {
            setupUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        preferredContentSize.height = tableView.contentSize.height
    }
    
    private func setupUI() {
        guard let routeParameters = routeParameters else {
            return
        }
        
        findBestSequenceSwitch?.isOn = routeParameters.findBestSequence
        preserveFirstStopSwitch?.isOn = routeParameters.preserveFirstStop
        preserveLastStopSwitch?.isOn = routeParameters.preserveLastStop
    }

    // MARK: - Actions
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case findBestSequenceSwitch:
            routeParameters?.findBestSequence = sender.isOn
            let sections: IndexSet = [1]
            tableView.performBatchUpdates({
                if sender.isOn {
                    tableView?.insertSections(sections, with: .fade)
                } else {
                    tableView?.deleteSections(sections, with: .fade)
                }
            }, completion: { (finished) in
                guard finished else {
                    return
                }
                self.preferredContentSize.height = self.tableView.contentSize.height
            })
            setupUI()
        case preserveFirstStopSwitch:
            routeParameters?.preserveFirstStop = sender.isOn
        case preserveLastStopSwitch:
            routeParameters?.preserveLastStop = sender.isOn
        default:
            break
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let superCount = super.numberOfSections(in: tableView)
        if routeParameters?.findBestSequence == false {
            return superCount - 1
        }
        return superCount
    }
}
