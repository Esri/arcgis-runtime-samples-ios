// Copyright 2022 Esri.
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

class MobileGeodatabaseTableViewController: UITableViewController {
    var oidArray = [Int]()
    var collectionTimeStamps = [Date]()
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
            dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "OID and Collection Timestamp"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return oidArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "featureCell", for: indexPath)
        cell.textLabel?.text = String(oidArray[indexPath.row])
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM d HH:mm:ss zzz yyyy"
        let timeStamp = formatter.string(from: collectionTimeStamps[indexPath.row])
        cell.detailTextLabel?.text = timeStamp
        return cell
    }
}
