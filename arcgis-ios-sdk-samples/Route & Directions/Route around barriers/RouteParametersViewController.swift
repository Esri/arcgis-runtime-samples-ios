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
            if sender.isOn {
                tableView?.insertSections([1], with: .fade)
            } else {
                tableView?.deleteSections([1], with: .fade)
            }
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
        if routeParameters?.findBestSequence == false {
            return 1
        }
        return super.numberOfSections(in: tableView)
    }

}
