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
    // An array to hold all the features' OIDs.
    var oidArray = [Int]()
    // An array to store all the features' time stamps.
    var collectionTimeStamps = [Date]()
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
            dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "OID and Collection Timestamp"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return oidArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "featureCell", for: indexPath)
        // Set the cell's text to the feature's OID.
        cell.textLabel?.text = String(oidArray[indexPath.row])
        // Create a formatter for the date.
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM d HH:mm:ss zzz yyyy"
        // Convert the current date to a string.
        let timeStamp = formatter.string(from: collectionTimeStamps[indexPath.row])
        // Set the cell's detail text to the time stamp.
        cell.detailTextLabel?.text = timeStamp
        return cell
    }
}
