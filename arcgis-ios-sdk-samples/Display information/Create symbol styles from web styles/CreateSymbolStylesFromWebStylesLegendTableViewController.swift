// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class CreateSymbolStylesFromWebStylesLegendTableViewController: UITableViewController {
    /// The symbols to display in the legend table.
    var symbols: [(name: String, symbol: AGSSymbol)]?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        symbols?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Symbol Styles"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SymbolLegendCell", for: indexPath)
        // Display the name of the symbol.
        cell.textLabel?.text = symbols?[indexPath.row].name
        // Create an icon swatch for the symbol and update the cell.
        symbols?[indexPath.row].symbol.createSwatch { (image, _) in
            if let updateCell = tableView.cellForRow(at: indexPath) {
                updateCell.imageView?.image = image
                updateCell.setNeedsLayout()
            }
        }
        return cell
    }
}
