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
    
    func showPicker(picker: String) {
        tableView.performBatchUpdates({
        switch picker {
        case "point":
            pointLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.iconPicker], with: .fade)
        case "polyline":
            polylineLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.polylinePicker], with: .fade)
        case "polygon":
            polygonLabel?.textColor = view.tintColor
            tableView.insertRows(at: [.polygonPicker], with: .fade)
        default:
            break
        }
        }, completion: nil)
    }
        
    func hidePicker(picker: String) {
        print("called hidePicker")
        tableView.performBatchUpdates({
        switch picker {
        case "point":
            if !polylinePickerHidden {
                polylineLabel?.textColor = nil
                tableView.deleteRows(at: [.polylinePicker], with: .fade)
                polylinePickerHidden = true
            } else if !polygonPickerHidden {
                polygonLabel?.textColor = nil
                tableView.deleteRows(at: [.polygonPicker], with: .fade)
                polygonPickerHidden = true
            }
        case "polyline":
            if !iconPickerHidden {
                iconLabel?.textColor = nil
                tableView.deleteRows(at: [.iconPicker], with: .fade)
               iconPickerHidden = true
            } else if !polygonPickerHidden {
                polygonLabel?.textColor = nil
                tableView.deleteRows(at: [.polygonPicker], with: .fade)
                polygonPickerHidden = true
            }
        case "polylgon":
            if !iconPickerHidden {
                iconLabel?.textColor = nil
                tableView.deleteRows(at: [.iconPicker], with: .fade)
                iconPickerHidden = true
            } else if !polylinePickerHidden {
                polylineLabel?.textColor = nil
                tableView.deleteRows(at: [.polylinePicker], with: .fade)
                polylinePickerHidden = true
            }
        default:
            break
        }
        }, completion: nil)
    }
}
    
//    // Prompt the icon picker to either appear or disappear.
//    func toggleIconPickerVisibility() {
//        print("called icon picker")
//        tableView.performBatchUpdates({
//        if !iconPickerHidden {
//            pointLabel?.textColor = view.tintColor
//            tableView.insertRows(at: [.iconPicker], with: .fade)
//            iconPickerHidden = false
//            print("set iconPickerHidden to false")
//        } else {
//            iconLabel?.textColor = nil
//            tableView.deleteRows(at: [.iconPicker], with: .fade)
//            iconPickerHidden = true
//        }
//        }, completion: nil)
//    }
//
//    // Prompt the polyline picker to either appear or disappear.
//    func togglePolylinePickerVisibility() {
//        print("called polyline picker")
//        tableView.performBatchUpdates({
//        if !polylinePickerHidden {
//            polylineLabel?.textColor = view.tintColor
//            tableView.insertRows(at: [.polylinePicker], with: .fade)
//            polylinePickerHidden = false
//            print("set polinePickerHidden to false")
//        } else {
//            polylineLabel?.textColor = nil
//            tableView.deleteRows(at: [.polylinePicker], with: .fade)
//            polylinePickerHidden = true
//        }
//        }, completion: nil)
//    }
//
//    // Prompt the polygon picker to either appear or disappear.
//    func togglePolygonPickerVisibility() {
//        print("called polygon picker")
//        tableView.performBatchUpdates({
//        if !polygonPickerHidden {
//            polygonLabel?.textColor = view.tintColor
//            tableView.insertRows(at: [.polygonPicker], with: .fade)
//            polygonPickerHidden = false
//            print("set polygonPickerHidden to false")
//        } else {
//            polygonLabel?.textColor = nil
//            tableView.deleteRows(at: [.polygonPicker], with: .fade)
//            polygonPickerHidden = true
//        }
//        }, completion: nil)
//    }
    
// Set an index path for each table view cell.
private extension IndexPath {
    static let pointLabel = IndexPath(row: 0, section: 0)
    static let iconPicker = IndexPath(row: 1, section: 0)
    static let polylineLabel = IndexPath(row: 2, section: 0)
    static let polylinePicker = IndexPath(row: 3, section: 0)
    static let polygonLabel = IndexPath(row: 4, section: 0)
    static let polygonPicker = IndexPath(row: 5, section: 0)
}

// Adjust the index path according to which pickers are hidden.
extension CreateAndSaveKMLSettingsViewController /* UITableViewDataSource */ {
    func adjustedIndexPath(_ indexPath: IndexPath) -> IndexPath {
//        switch indexPath.section {
//        case 0:
//            var adjustedRow = indexPath.row
//            if indexPath.row >= 1 && iconPickerHidden {
//                adjustedRow += 1
//            } else if indexPath.row >= 2 && polylinePickerHidden {
//                adjustedRow += 1
//            } else if indexPath.row >= 3 && polygonPickerHidden {
//                adjustedRow += 1
//            }
//            print("reg: \(indexPath.row)")
//            print("adjusted: \(adjustedRow)")
//            return IndexPath(row: adjustedRow, section: indexPath.section)
//        default:
//            return indexPath
//        }
        var adjustedRow = indexPath.row
        if indexPath.row > 0 && iconPickerHidden && polylinePickerHidden && polygonPickerHidden {
            if indexPath.row >= 2 {
                adjustedRow += 2
            } else {
                adjustedRow += 1
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        } else if indexPath.row > 1 && !iconPickerHidden && polylinePickerHidden && polygonPickerHidden {
            if indexPath.row == 3 {
                adjustedRow += 1
            } else {
                adjustedRow += 2
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        } else if indexPath.row == 1 && iconPickerHidden && !polylinePickerHidden && polygonPickerHidden {
            adjustedRow += 1
            return IndexPath(row: adjustedRow, section: indexPath.section)
        } else if indexPath.row > 0 && iconPickerHidden && polylinePickerHidden && !polygonPickerHidden {
            if indexPath.row >= 2 {
                adjustedRow += 2
            } else {
                adjustedRow += 1
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if iconPickerHidden {
            numberOfRows -= 1
        }
        if polylinePickerHidden {
            numberOfRows -= 1
        }
        if polygonPickerHidden {
            numberOfRows -= 1
        }
        return numberOfRows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Add "no style" to options on point polyline polygon
        return super.tableView(tableView, cellForRowAt: adjustedIndexPath(indexPath))
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
        switch Section.allCases[pickerView.tag] {
        case .iconPicker:
            let iconKey = possibleIcons[row]
            let iconURL = iconDictionary[iconKey]
            icon = AGSKMLIcon(url: iconURL!)
            iconLabel!.text = iconKey
            return feature = "point"
        case .polylinePicker:
            let colorKey = possibleColors[row]
//            colorLabel!.text = colorKey
            return color = colorDictionary[colorKey]! //returns UIColor
        case .polygonPicker:
            let colorKey = possibleColors[row]
//            colorLabel!.text = colorKey
            return color = colorDictionary[colorKey]! //returns UIColor
        }
    }
}

extension CreateAndSaveKMLSettingsViewController /* UITableViewDelegate */ {
    // Deselect the row and return the selected feature.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch adjustedIndexPath(indexPath) {
        case .pointLabel:
            tableView.deselectRow(at: adjustedIndexPath(indexPath), animated: true)
            // change text of right detail
            showPicker(picker: "point")
            hidePicker(picker: "point")
            return feature = "point"
        case .polylineLabel:
            tableView.deselectRow(at: indexPath, animated: true)
            showPicker(picker: "polyline")
            hidePicker(picker: "polyline")
            return feature = "polyline"
        case .polygonLabel:
            tableView.deselectRow(at: indexPath, animated: true)
            polygonPickerHidden = false
            showPicker(picker: "polygon")
            hidePicker(picker: "polygon")
            return feature = "polygon"
        default:
            break
        }
    }
}
