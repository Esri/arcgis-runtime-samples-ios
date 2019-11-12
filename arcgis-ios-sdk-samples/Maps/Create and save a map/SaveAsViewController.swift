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

protocol SaveAsViewControllerDelegate: AnyObject {
    func saveAsViewController(_ saveAsViewController: SaveAsViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String)
}

class SaveAsViewController: UITableViewController {
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var tagsTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    
    weak var delegate: SaveAsViewControllerDelegate?
    
    // MARK: - Actions
    
    @IBAction private func cancelAction() {
        dismiss(animated: true)
    }
    
    @IBAction private func saveAction() {
        guard let title = titleTextField.text,
            !title.isEmpty else {
            //show error message
            presentAlert(message: "Please enter a title.")
            return
        }
        
        let tags = tagsTextField.text?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        
        let itemDescription = descriptionTextField.text ?? ""
        delegate?.saveAsViewController(self, didInitiateSaveWithTitle: title, tags: tags, itemDescription: itemDescription)
    }
}
