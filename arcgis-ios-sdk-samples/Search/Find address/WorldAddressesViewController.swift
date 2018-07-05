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


protocol WorldAddressesVCDelegate:class {
    func worldAddressesViewController(_ worldAddressesViewController: WorldAddressesViewController, didSelectAddress address:String)
}
    
class WorldAddressesViewController: UITableViewController {
        
        weak var delegate:WorldAddressesVCDelegate?
        
        private var addresses = ["277 N Avenida Caballeros, Palm Springs, CA", "380 New York St, Redlands, CA 92373", "Београд", "Москва", "北京"]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
        }
        
        // MARK: - Table view data source
        
        override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.addresses.count
        }
        
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
            cell.textLabel?.text = self.addresses[indexPath.row]
            
            return cell
        }
        
        // MARK: - Table view delegate
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let address = self.addresses[indexPath.row]
            self.delegate?.worldAddressesViewController(self, didSelectAddress: address)
        }
        
}
