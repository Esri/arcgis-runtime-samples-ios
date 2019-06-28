//
// Copyright © 2019 Esri.
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

protocol ReadSymbolsFromMobileStyleSymbolSettingsViewControllerDelegate: AnyObject {
    func symbolSettingsViewControllerSettingsDidChange(_ controller: ReadSymbolsFromMobileStyleSymbolSettingsViewController)
}

class ReadSymbolsFromMobileStyleSymbolSettingsViewController: UITableViewController {
    weak var delegate: ReadSymbolsFromMobileStyleSymbolSettingsViewControllerDelegate?
    
    var eyes = [AGSSymbolStyleSearchResult]() {
        didSet {
            selectedEyes = eyes.first
            tableView.reloadSections([Section.eyes.rawValue], with: .automatic)
        }
    }
    var mouths = [AGSSymbolStyleSearchResult]() {
        didSet {
            selectedMouth = mouths.first
            tableView.reloadSections([Section.mouths.rawValue], with: .automatic)
        }
    }
    var hats = [AGSSymbolStyleSearchResult]() {
        didSet {
            selectedHat = hats.first
            tableView.reloadSections([Section.hats.rawValue], with: .automatic)
        }
    }
    
    private(set) var selectedEyes: AGSSymbolStyleSearchResult?
    private(set) var selectedMouth: AGSSymbolStyleSearchResult?
    private(set) var selectedHat: AGSSymbolStyleSearchResult?
    private(set) var selectedColor = UIColor.yellow
    private(set) var selectedSize = 40
    
    enum Section: Int, CaseIterable {
        case eyes
        case mouths
        case hats
        case other
    }
    
    func selection(for section: Section) -> AGSSymbolStyleSearchResult? {
        switch section {
        case .eyes:
            return selectedEyes
        case .mouths:
            return selectedMouth
        case .hats:
            return selectedHat
        case .other:
            return nil
        }
    }
    
    func selectSearchResult(_ searchResult: AGSSymbolStyleSearchResult, in section: Section) {
        switch section {
        case .eyes:
            selectedEyes = searchResult
        case .mouths:
            selectedMouth = searchResult
        case .hats:
            selectedHat = searchResult
        case .other:
            break
        }
    }
    
    private var cachedImages = [IndexPath: UIImage]()
    private var imageOperations = [IndexPath: AGSCancelable]()
    
    func searchResultForRow(at indexPath: IndexPath) -> AGSSymbolStyleSearchResult? {
        switch Section.allCases[indexPath.section] {
        case .eyes:
            return eyes[indexPath.row]
        case .mouths:
            return mouths[indexPath.row]
        case .hats:
            return hats[indexPath.row]
        case .other:
            return nil
        }
    }
    
    func indexPathOfRow(for searchResult: AGSSymbolStyleSearchResult) -> IndexPath? {
        if let row = eyes.firstIndex(of: searchResult) {
            return IndexPath(row: row, section: Section.eyes.rawValue)
        } else if let row = mouths.firstIndex(of: searchResult) {
            return IndexPath(row: row, section: Section.mouths.rawValue)
        } else if let row = hats.firstIndex(of: searchResult) {
            return IndexPath(row: row, section: Section.hats.rawValue)
        } else {
            return nil
        }
    }
    
    @discardableResult
    func createImageForRow(at indexPath: IndexPath) -> UIImage? {
        guard let searchResult = searchResultForRow(at: indexPath) else {
            return nil
        }
        if let image = cachedImages[indexPath] {
            return image
        } else if imageOperations[indexPath] != nil {
            return nil
        } else {
            let operation = searchResult.symbol?.createSwatch(withWidth: 40, height: 40, screen: .main, backgroundColor: nil) { [weak self] (image, error) in
                guard let self = self else { return }
                self.imageOperations[indexPath] = nil
                if let image = image {
                    self.cachedImages[indexPath] = image
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                } else if let error = error {
                    print("Error cerating swatch: \(error)")
                }
            }
            imageOperations[indexPath] = operation
            return nil
        }
    }
    
    func cancelCreationOfImageForRow(at indexPath: IndexPath) {
        guard let operation = imageOperations.removeValue(forKey: indexPath) else { return }
        operation.cancel()
    }
}

extension ReadSymbolsFromMobileStyleSymbolSettingsViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { createImageForRow(at: $0) }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { cancelCreationOfImageForRow(at: $0) }
    }
}

extension ReadSymbolsFromMobileStyleSymbolSettingsViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .eyes:
            return eyes.count
        case .mouths:
            return mouths.count
        case .hats:
            return hats.count
        case .other:
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .eyes, .mouths, .hats:
            let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
            cell.textLabel?.text = searchResultForRow(at: indexPath)?.name
            cell.imageView?.image = createImageForRow(at: indexPath)
            cell.accessoryType = {
                if searchResultForRow(at: indexPath) == selection(for: section) {
                    return .checkmark
                } else {
                    return .none
                }
            }()
            return cell
        case .other:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "color", for: indexPath) as! ReadSymbolsFromMobileStyleSymbolSettingsColorCell
                cell.color = selectedColor
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "size", for: indexPath) as! ReadSymbolsFromMobileStyleSymbolSettingsSizeCell
                cell.delegate = self
                cell.slider.minimumValue = Float(20)
                cell.slider.maximumValue = Float(60)
                cell.slider.value = Float(selectedSize)
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.allCases[section] {
        case .eyes:
            return "Eyes"
        case .mouths:
            return "Mouths"
        case .hats:
            return "Hats"
        case .other:
            return nil
        }
    }
}

extension ReadSymbolsFromMobileStyleSymbolSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = Section.allCases[indexPath.section]
        switch section {
        case .eyes, .mouths, .hats:
            if let previousSelection = selection(for: Section.allCases[indexPath.section]),
                let indexPath = self.indexPathOfRow(for: previousSelection) {
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            }
            if let searchResult = searchResultForRow(at: indexPath) {
                selectSearchResult(searchResult, in: section)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                delegate?.symbolSettingsViewControllerSettingsDidChange(self)
            }
        case .other:
            if indexPath.row == 0 {
                let colorPickerViewController = ColorPickerViewController.instantiateWith(color: selectedColor) { [weak self] (newColor) in
                    guard let self = self else { return }
                    self.selectedColor = newColor
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    self.delegate?.symbolSettingsViewControllerSettingsDidChange(self)
                }
                show(colorPickerViewController, sender: self)
            }
        }
    }
}

extension ReadSymbolsFromMobileStyleSymbolSettingsViewController: ReadSymbolsFromMobileStyleSymbolSettingsSizeCellDelegate {
    func sizeCellSizeDidChange(_ cell: ReadSymbolsFromMobileStyleSymbolSettingsSizeCell) {
        selectedSize = Int(cell.slider.value.rounded())
        delegate?.symbolSettingsViewControllerSettingsDidChange(self)
    }
}

class ReadSymbolsFromMobileStyleSymbolSettingsColorCell: UITableViewCell {
    @IBOutlet var colorView: UIView! {
        didSet {
            colorView.layer.cornerRadius = 5
            colorView.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1).cgColor
            colorView.layer.borderWidth = 1
        }
    }
    
    var color: UIColor? {
        didSet {
            colorView.backgroundColor = color
        }
    }
}

protocol ReadSymbolsFromMobileStyleSymbolSettingsSizeCellDelegate: AnyObject {
    func sizeCellSizeDidChange(_ cell: ReadSymbolsFromMobileStyleSymbolSettingsSizeCell)
}

class ReadSymbolsFromMobileStyleSymbolSettingsSizeCell: UITableViewCell {
    @IBOutlet var slider: UISlider!
    
    weak var delegate: ReadSymbolsFromMobileStyleSymbolSettingsSizeCellDelegate?
    
    @IBAction func updateSize() {
        delegate?.sizeCellSizeDidChange(self)
    }
}
