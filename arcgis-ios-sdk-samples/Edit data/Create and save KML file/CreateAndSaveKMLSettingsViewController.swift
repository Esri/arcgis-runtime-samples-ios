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

/// The delegate of a `MapReferenceScaleSettingsViewController`.
protocol CreateAndSaveKMLSettingsViewControllerDelegate: AnyObject {
    ///
    func createAndSaveKMLSettingsViewController(_ createAndSaveKMLSettingsViewController: CreateAndSaveKMLSettingsViewController, feature: String, icon: AGSKMLIcon?, color: UIColor)
    ///
    /// - Parameter controller: The controller sending the message.
    /// Tells the delegate that the user finished changing settings.
    func createAndSaveKMLSettingsViewControllerDidFinish(_ controller: CreateAndSaveKMLSettingsViewController)
}

class CreateAndSaveKMLSettingsViewController: UITableViewController {
    weak var delegate: CreateAndSaveKMLSettingsViewControllerDelegate?
    var icon = AGSKMLIcon(url: URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueSquareLargeB.png")!)
    var color = UIColor.red
    var feature = "point"
    @IBOutlet var pointLabel: UITableViewCell?
    @IBOutlet var iconLabel: UILabel?
    @IBOutlet var colorLabel: UILabel?
    
    @IBAction func done() {
        delegate?.createAndSaveKMLSettingsViewController(self, feature: feature, icon: icon, color: color)
        delegate?.createAndSaveKMLSettingsViewControllerDidFinish(self)
    }
    
    var kmlStyle = AGSKMLStyle()
    private var iconPickerHidden = true
    private var colorPickerHidden = true
    private let possibleIcons = ["Star", "Diamond", "Circle", "Square", "Round pin", "Square pin"]
    private let possibleColors = ["Red", "Yellow", "White", "Purple", "Orange", "Magenta", "Light gray", "Gray", "Dark gray", "Green", "Cyan", "Brown", "Blue", "Black"]
    private let iconDictionary = [
        "Star": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueStarLargeB.png")!,
        "Diamond": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueDiamondLargeB.png")!,
        "Circle": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueCircleLargeB.png")!,
        "Square": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueSquareLargeB.png")!,
        "Round pin": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BluePin1LargeB.png")!,
        "Square pin": URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BluePin2LargeB.png")!
    ]
    private let colorDictionary = ["Red": UIColor.red, "Yellow": UIColor.yellow, "White": UIColor.white, "Purple": UIColor.purple, "Orange": UIColor.orange, "Magenta": UIColor.magenta, "Light gray": UIColor.lightGray, "Gray": UIColor.gray, "Dark gray": UIColor.darkGray, "Green": UIColor.green, "Cyan": UIColor.cyan, "Brown": UIColor.brown, "Blue": UIColor.blue, "Black": UIColor.black]
    
    private enum Section: CaseIterable {
        case iconPicker, colorPicker
    }
    
    func toggleIconPickerVisibility() {
        tableView.performBatchUpdates({
        if iconPickerHidden {
            iconLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.iconPicker], with: .fade)
            iconPickerHidden = false
        } else if colorPickerHidden {
            colorLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.colorPicker], with: .fade)
            colorPickerHidden = false
        } else {
            iconLabel?.textColor = nil
            tableView.deleteRows(at: [.iconPicker], with: .fade)
            iconPickerHidden = true
            colorLabel?.textColor = nil
            tableView.deleteRows(at: [.colorPicker], with: .fade)
            colorPickerHidden = true
        }
        }, completion: nil)
    }
    
    func toggleColorPickerVisibility() {
        tableView.performBatchUpdates({
        if colorPickerHidden {
            colorLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.colorPicker], with: .fade)
            colorPickerHidden = false
        } else {
            colorLabel?.textColor = nil
            tableView.deleteRows(at: [.colorPicker], with: .fade)
            colorPickerHidden = true
        }
        }, completion: nil)
    }
}

private extension IndexPath {
    static let pointLabel = IndexPath(row: 0, section: 0)
    static let iconPicker = IndexPath(row: 1, section: 0)
    static let polylineLabel = IndexPath(row: 2, section: 0)
    static let polygonLabel = IndexPath(row: 3, section: 0)
    static let colorLabel = IndexPath(row: 0, section: 1)
    static let colorPicker = IndexPath(row: 1, section: 1)
}

extension CreateAndSaveKMLSettingsViewController /* UITableViewDataSource */ {
    func adjustedIndexPath(_ indexPath: IndexPath) -> IndexPath {
        switch indexPath.section {
        case 0:
            var adjustedRow = indexPath.row
            if indexPath.row >= 1 && iconPickerHidden {
                adjustedRow += 1
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        case 1:
            var adjustedRow = indexPath.row
            if indexPath.row >= 1 && colorPickerHidden {
                adjustedRow += 1
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if section == 0 && iconPickerHidden {
            return numberOfRows - 1
        } else if section == 1 && colorPickerHidden {
            return numberOfRows - 1
        } else {
            return numberOfRows
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return super.tableView(tableView, cellForRowAt: adjustedIndexPath(indexPath))
    }
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
    
    // Select the type of icon and color.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            let iconKey = possibleIcons[row]
            let iconURL = iconDictionary[iconKey]
            icon = AGSKMLIcon(url: iconURL!)
            return feature = "point"
        case .colorPicker:
            let colorKey = possibleColors[row]
            return color = colorDictionary[colorKey]! //returns UIColor
        }
    }
}

extension CreateAndSaveKMLSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch adjustedIndexPath(indexPath) {
        case .pointLabel:
            tableView.deselectRow(at: adjustedIndexPath(indexPath), animated: true)
            // change text of right detail
            toggleIconPickerVisibility()
        case .polylineLabel:
            return feature = "polyline"
        case .polygonLabel:
            return feature = "polygon"
        case .colorLabel:
            tableView.deselectRow(at: adjustedIndexPath(indexPath), animated: true)
            // change text of right detail
            toggleColorPickerVisibility()
        default:
            break
        }
    }
}
