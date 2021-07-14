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
    func saveAsViewController(_ saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String, folder: AGSPortalFolder?)
}

class SaveAsViewController: UITableViewController {
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var tagsTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var folderLabel: UILabel!
    
    /// The array of folders loaded from the portal.
    var portalFolders = [AGSPortalFolder]()
    /// Folder selected by the user.
    var selectedFolderIndex: Int?
    /// Use selectedFolderIndex to compute the selected folder.
    var selectedFolder: AGSPortalFolder? { selectedFolderIndex.map { portalFolders[$0] } }
    /// The SaveAsViewController delegate.
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
        // Get the tags from the text field.
        let tags = tagsTextField.text?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        // Get the item description from the text field.
        let itemDescription = descriptionTextField.text ?? ""
        
        delegate?.saveAsViewController(self, didInitiateSaveWithTitle: title, tags: tags, itemDescription: itemDescription, folder: selectedFolder)
    }
    
    /// Present the list of folders to choose from.
    func showFolderOptions() {
        // Set index for the default option.
        let selectedIndex = selectedFolderIndex ?? portalFolders.count
        // The titles of the portal folders and a "None" option.
        let folderTitles = portalFolders.map { $0.title ?? "(No Title)" } + ["None"]
        // Prepare the options table view controller and handle selection.
        let optionsViewController = OptionsTableViewController(labels: folderTitles, selectedIndex: selectedIndex) { [weak self] newIndex in
            guard let self = self else { return }
            // If "None" was selected, set selectedFolder to nil.
            if newIndex == self.portalFolders.count {
                self.selectedFolderIndex = nil
            } else {
                // Select the appropriate folder.
                self.selectedFolderIndex = newIndex
            }
            // Replace the label text with the selected option.
            self.folderLabel.text = self.selectedFolder?.title ?? "None"
        }
        optionsViewController.allowsEmptySelection = true
        optionsViewController.title = "Folders"
        show(optionsViewController, sender: self)
    }
}

extension SaveAsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folderCell = IndexPath(row: 3, section: 0)
        if indexPath == folderCell {
            showFolderOptions()
        }
    }
}
