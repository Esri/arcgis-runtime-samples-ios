//
// Copyright © 2020 Esri.
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
import ArcGIS

class CreateAndSaveKMLSettingsViewController: UITableViewController {
    var icon: String!
    var color: String!
    @IBOutlet var pointLabel: UITableViewCell!
    private let possibleIcons = ["Star", "Diamond", "Circle", "Square", "Round Pin", "Square Pin"]
    private let possibleColors = ["Red", "Yellow", "White", "Purple", "Orange", "Magenta", "Light gray", "Gray", "Dark gray", "Green", "Cyan", "Brown", "Blue", "Black"]
    private let colorDictionary = [UIColor.red: "red", UIColor.yellow: "yellow", UIColor.white: "white", UIColor.purple: "purple", UIColor.orange: "orange", UIColor.magenta: "magenta", UIColor.lightGray: "light gray", UIColor.gray: "gray", UIColor.darkGray: "dark gray", UIColor.green: "green", UIColor.cyan: "cyan", UIColor.brown: "brown", UIColor.blue: "blue", UIColor.black: "black"]
    
    private enum Section: CaseIterable {
        case iconPicker, colorPicker
    }
}

private extension IndexPath {
    static let pointLabel = IndexPath(row: 0, section: 0)
    static let colorLabel = IndexPath(row: 1, section: 0)
}

extension CreateAndSaveKMLSettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            return possibleIcons.count
        case .colorPicker:
            return possibleColors.count
        }
    }
}

extension CreateAndSaveKMLSettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            return possibleIcons[row]
        case .colorPicker:
            return possibleColors[row]
        }
    }
    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        switch Section.allCases[pickerView.tag] {
//        case .iconPicker:
//            return icon = possibleIcons[row]
//        case .colorPicker:
//            return color = possibleColors[row]
//        }
//    }
}

extension CreateAndSaveKMLSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case .pointLabel:
            tableView.deselectRow(at: indexPath, animated: true)
            // change text of right detail
            // toggle icon picker visibility
        case .colorLabel:
            tableView.deselectRow(at: indexPath, animated: true)
            // change text of right detail
        default:
            break
        }
    }
}
