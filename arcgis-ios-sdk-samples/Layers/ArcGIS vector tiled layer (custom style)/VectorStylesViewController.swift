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
//

import UIKit

protocol VectorStylesVCDelegate: AnyObject {
    
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID:String)
}

class VectorStylesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var itemIDs = ["1349bfa0ed08485d8a92c442a3850b06", "bd8ac41667014d98b933e97713ba8377", "02f85ec376084c508b9c8e5a311724fa", "1bf0cc4a4380468fbbff107e100f65a5"]
    
    weak var delegate: VectorStylesVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 10
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "Cell\(indexPath.row)"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.backgroundColor = .clear
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID = self.itemIDs[indexPath.row]
        self.delegate?.vectorStylesViewController(self, didSelectItemWithID: itemID)
    }
}
