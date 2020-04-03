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
    var icon = AGSKMLIcon(url: URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueStarLargeB.png")!)
    var color = UIColor.red
    var feature = "point"
    @IBOutlet var pointLabel: UILabel?
    @IBOutlet var polylineLabel: UILabel?
    @IBOutlet var polygonLabel: UILabel?
    @IBOutlet var iconLabel: UILabel?
    
    // Complete settings changes and go back to the main page.
    @IBAction func done() {
        delegate?.createAndSaveKMLSettingsViewController(self, feature: feature, icon: icon, color: color)
        delegate?.createAndSaveKMLSettingsViewControllerDidFinish(self)
    }
    
    var kmlStyle = AGSKMLStyle()
    private var iconPickerHidden = true
    private var polylinePickerHidden = true
    private var polygonPickerHidden = true
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
        case iconPicker, polylinePicker, polygonPicker
    }
    
    func hideAllPickers() {
        tableView.performBatchUpdates({
            if !iconPickerHidden {
                iconLabel?.textColor = nil
                pointLabel?.textColor = nil
                tableView.deleteRows(at: [.iconPickerPath], with: .fade)
                iconPickerHidden = true
            }
            if !polylinePickerHidden {
                polylineLabel?.textColor = nil
                tableView.deleteRows(at: [.polylinePickerPath], with: .fade)
                polylinePickerHidden = true
            }
            if !polygonPickerHidden {
                polygonLabel?.textColor = nil
                tableView.deleteRows(at: [.polygonPickerPath], with: .fade)
                polygonPickerHidden = true
            }
        }, completion: nil)
    }
    
    // Prompt the icon picker to either appear or disappear.
    func showIconPicker() {
        tableView.performBatchUpdates({
            pointLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.iconPickerPath], with: .fade)
            iconPickerHidden = false
        }, completion: nil)
    }
    
    // Prompt the polyline picker to either appear or disappear.
    func showPolylinePicker() {
        tableView.performBatchUpdates({
            polylineLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.polylinePickerPath], with: .fade)
            polylinePickerHidden = false
        }, completion: nil)
    }
    
    // Prompt the polygon picker to either appear or disappear.
    func showPolygonPicker() {
        tableView.performBatchUpdates({
            polygonLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.polygonPickerPath], with: .fade)
            polygonPickerHidden = false
        }, completion: nil)
    }
}

// Set an index path for each table view cell.
private extension IndexPath {
    static let pointLabelPath = IndexPath(row: 0, section: 0)
    static let polylineLabelPath = IndexPath(row: 2, section: 0)
    static let polygonLabelPath = IndexPath(row: 4, section: 0)
    
    static let iconPickerPath = IndexPath(row: 1, section: 0)
    static let polylinePickerPath = IndexPath(row: 2, section: 0)
    static let polygonPickerPath = IndexPath(row: 3, section: 0)
}

// Adjust the index path according to which pickers are hidden.
extension CreateAndSaveKMLSettingsViewController /* UITableViewDataSource */ {
    #warning("This function can be improved. Just list all the states and find a easier way to handle each state.")
    func adjustedIndexPath(_ indexPath: IndexPath) -> IndexPath {
        var adjustedRow = -1
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                adjustedRow = 0
            } else if indexPath.row == 1 && iconPickerHidden {
                adjustedRow = 2
            } else if indexPath.row == 2 && iconPickerHidden && polylinePickerHidden {
                adjustedRow = 4
            } else if indexPath.row == 3 && polygonPickerHidden {
                adjustedRow = 4
            }
        }
        return IndexPath(row: adjustedRow, section: 0)
    }
    
    func loadCellPath(_ indexPath: IndexPath) -> IndexPath {
        var adjustedRow = indexPath.row
        if indexPath.row >= 1 && iconPickerHidden {
            adjustedRow += 1
        }
        if indexPath.row >= 2 && polylinePickerHidden {
            adjustedRow += 1
        }
        if indexPath.row >= 3 && polygonPickerHidden {
            adjustedRow += 1
        }
        return IndexPath(row: adjustedRow, section: 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if iconPickerHidden && polylinePickerHidden && polygonPickerHidden {
            numberOfRows = 3
        } else {
            numberOfRows = 4
        }
        return numberOfRows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Add "no style" to options on point polyline polygon
        return super.tableView(tableView, cellForRowAt: loadCellPath(indexPath))
    }
    
    // Deselect the row and return the selected feature.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = adjustedIndexPath(indexPath)
        hideAllPickers()
        tableView.deselectRow(at: indexPath, animated: true)
        switch path {
        case .pointLabelPath:
            showIconPicker()
        case .polylineLabelPath:
            showPolylinePicker()
        case .polygonLabelPath:
            showPolygonPicker()
        default:
            break
        }
    }
}

// Make the picker views with the appropriate number of columns and rows.
extension CreateAndSaveKMLSettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            return possibleIcons.count
        case .polylinePicker:
            return possibleColors.count
        case .polygonPicker:
            return possibleColors.count
        }
    }
}

extension CreateAndSaveKMLSettingsViewController: UIPickerViewDelegate {
    // Fill the picker views with the appropriate data. 
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            return possibleIcons[row]
        case .polylinePicker:
            return possibleColors[row]
        case .polygonPicker:
            return possibleColors[row]
        }
    }
    
    // Select the type of icon and color.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        hideAllPickers()
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            let iconKey = possibleIcons[row]
            let iconURL = iconDictionary[iconKey]
            icon = AGSKMLIcon(url: iconURL!)
            iconLabel?.text = iconKey
        //            return feature = "point"
        case .polylinePicker:
            let colorKey = possibleColors[row]
            //            colorLabel!.text = colorKey
            polylineLabel?.backgroundColor = colorDictionary[colorKey]!
        //            return color = colorDictionary[colorKey]! //returns UIColor
        case .polygonPicker:
            let colorKey = possibleColors[row]
            polygonLabel?.backgroundColor = colorDictionary[colorKey]!
            //            colorLabel!.text = colorKey
            //            return color = colorDictionary[colorKey]! //returns UIColor
        }
    }
}
