// Copyright 2018 Esri.
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

/// A basic interface for selecting one options from a list,
/// showing the checkmark accessory for the selected cell.
class OptionsTableViewController: UITableViewController {
    struct Option {
        let label: String
        let image: UIImage?
        
        init(label: String, image: UIImage? = nil) {
            self.label = label
            self.image = image
        }
    }
    
    private let options: [Option]
    private var selectedIndex: Int
    private let onChange: (Int) -> Void
    
    convenience init(labels: [String], selectedIndex: Int, onChange: @escaping (Int) -> Void) {
        let options = labels.map { Option(label: $0) }
        self.init(options: options, selectedIndex: selectedIndex, onChange: onChange)
    }
    
    init(options: [Option], selectedIndex: Int, onChange: @escaping (Int) -> Void) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.onChange = onChange
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
    }
    
    // UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        let option = options[indexPath.row]
        cell.textLabel?.text = option.label
        cell.imageView?.image = option.image
        cell.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
        return cell
    }
    
    // UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPathOfPreviouslySelectedRow = IndexPath(row: selectedIndex, section: indexPath.section)
        let indexPathsToReload = [indexPathOfPreviouslySelectedRow, indexPath]
        selectedIndex = indexPath.row
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
        onChange(indexPath.row)
    }
}
