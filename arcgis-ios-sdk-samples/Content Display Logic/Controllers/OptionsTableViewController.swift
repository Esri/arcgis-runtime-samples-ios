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

protocol OptionProtocol: Equatable {
    /// The title of the option.
    var title: String { get }
}

/// A basic interface for selecting one options from a list,
/// showing the checkmark accessory for the selected cell.
class OptionsTableViewController<Option: OptionProtocol>: UITableViewController {
    
    private let options: [Option]
    private var selectedOption: Option
    private let onChange: (Option) -> Void
    
    init<S: Sequence>(options: S, selectedOption: S.Element, onChange: @escaping (S.Element) -> Void) where S.Element == Option {
        self.options = Array(options)
        self.selectedOption = selectedOption
        self.onChange = onChange
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(OptionCell.self, forCellReuseIdentifier: "OptionCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let row = options.index(of: selectedOption) {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
    }
    
    // UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        cell.textLabel?.text = option.title
        return cell
    }
    
    // UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onChange(options[indexPath.row])
    }
    
}

class OptionCell: UITableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }
}
