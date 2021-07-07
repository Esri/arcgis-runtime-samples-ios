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
    var selectedFolder: AGSPortalFolder?
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
        let selectedIndex = portalFolders.firstIndex { $0 == selectedFolder } ?? portalFolders.count
        // The titles of the portal folders and a "No folder" option.
        let folderTitles = portalFolders.map { $0.title! } + ["No folder"]
        // Prepare the options table view controller and handle selection.
        let optionsViewController = OptionsTableViewController(labels: folderTitles, selectedIndex: selectedIndex) { [weak self] newIndex in
            guard let self = self else { return }
            // If "No folder" was selected, set selectedFolder to nil.
            if newIndex == self.portalFolders.count {
                self.selectedFolder = nil
            } else {
                // Select the appropriate folder.
                self.selectedFolder = self.portalFolders[newIndex]
            }
            // Replace the label text with the selected option.
            self.folderLabel.text = self.selectedFolder?.title ?? "No folder"
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Folders"
        show(optionsViewController, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SaveAsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folderCell = IndexPath(row: 3, section: 0)
        if indexPath == folderCell {
            tableView.deselectRow(at: folderCell, animated: true)
            showFolderOptions()
        }
    }
}
