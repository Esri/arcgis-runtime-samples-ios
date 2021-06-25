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
import ArcGIS

protocol SaveAsViewControllerDelegate: AnyObject {
    func saveAsViewController(_ saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String, folder: AGSPortalFolder)
}

class SaveAsViewController: UITableViewController {
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var tagsTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var folderLabel: UILabel!
    
    /// Indicates whether the reference scale picker is currently hidden.
    private var folderPickerHidden = true
    let folderPicker = IndexPath(row: 4, section: 0)
    var portalFolders = [AGSPortalFolder]()
    var selectedFolder: AGSPortalFolder?
    weak var delegate: SaveAsViewControllerDelegate?
    
    // MARK: - Actions
    
    @IBAction private func cancelAction() {
        dismiss(animated: true)
    }
    
    @IBAction private func saveAction() {
        guard let title = titleTextField.text,
              !title.isEmpty else {
            // Show error message.
            presentAlert(message: "Please enter a title.")
            return
        }
        
        guard let folder = selectedFolder,
              selectedFolder != nil else {
            // Show error message.
            presentAlert(message: "Please select a folder.")
            return
        }
        let tags = tagsTextField.text?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        
        let itemDescription = descriptionTextField.text ?? ""
        delegate?.saveAsViewController(self, didInitiateSaveWithTitle: title, tags: tags, itemDescription: itemDescription, folder: folder)
    }
    
    /// Toggles visisbility of the reference scale picker.
    func toggleFolderPickerVisibility() {
        tableView.performBatchUpdates({
        if folderPickerHidden {
            folderLabel.textColor = .accentColor
            tableView.insertRows(at: [folderPicker], with: .fade)
            folderPickerHidden = false
        } else {
            folderLabel.textColor = nil
            tableView.deleteRows(at: [folderPicker], with: .fade)
            folderPickerHidden = true
        }
        }, completion: nil)
    }
}

extension SaveAsViewController /* UITableViewDataSource */ {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if section == 0 && folderPickerHidden {
            return numberOfRows - 1
        } else {
            return numberOfRows
        }
    }
}

extension SaveAsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folderCell = IndexPath(row: 3, section: 0)
        if indexPath == folderCell {
            tableView.deselectRow(at: folderCell, animated: true)
            toggleFolderPickerVisibility()
        }
    }
}

extension SaveAsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return portalFolders.count // user loaded folders
    }
}

extension SaveAsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return portalFolders[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFolder = portalFolders[row]
    }
}
