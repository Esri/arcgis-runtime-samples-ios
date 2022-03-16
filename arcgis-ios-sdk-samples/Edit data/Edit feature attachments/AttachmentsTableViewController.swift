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

class AttachmentsTableViewController: UITableViewController {
    var feature: AGSArcGISFeature! {
        didSet {
            loadAttachments()
        }
    }
    
    /// The service geodatabase that contains damaged property features.
    var serviceGeodatabase: AGSServiceGeodatabase!
    
    private var attachments: [AGSAttachment] = []
    
    private func loadAttachments() {
        // Show progress HUD.
        UIApplication.shared.showProgressHUD(message: "Loading attachments")
        
        feature?.fetchAttachments { [weak self] (attachments: [AGSAttachment]?, error: Error?) in
            // Dismiss progress HUD.
            UIApplication.shared.hideProgressHUD()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let attachments = attachments {
                self.attachments = attachments
                self.tableView?.reloadData()
            }
        }
    }
    
    private func deleteAttachment(_ attachment: AGSAttachment) {
        feature?.delete(attachment) { [weak self] (error: Error?) in
            guard let self = self else {
                return
            }
            if let error = error {
                print(error)
            } else if let attachmentIndex = self.attachments.firstIndex(of: attachment) {
                let indexPathToRemove = IndexPath(row: attachmentIndex, section: 0)
                // update the model
                self.attachments.remove(at: attachmentIndex)
                // update the table
                self.tableView.deleteRows(at: [indexPathToRemove], with: .automatic)
            }
        }
    }
    
    private func downloadImage(for attachment: AGSAttachment) {
        UIApplication.shared.showProgressHUD(message: "Downloading attachment")
        
        attachment.fetchData { [weak self] (data: Data?, error: Error?) in
            UIApplication.shared.hideProgressHUD()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                print(error)
            } else if let data = data,
                let index = self.attachments.firstIndex(of: attachment),
                let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                cell.imageView?.image = UIImage(data: data)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentCell", for: indexPath)
        let attachment = attachments[indexPath.row]
        cell.textLabel?.text = attachment.name
        cell.imageView?.contentMode = .scaleAspectFit
        if attachment.hasFetchedData {
            attachment.fetchData { (data, _) in
                if let data = data {
                    cell.imageView?.image = UIImage(data: data)
                }
            }
        } else {
            cell.imageView?.image = UIImage(named: "CloudDownload", in: AGSBundle(), compatibleWith: nil)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !attachments[indexPath.row].hasFetchedData
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        downloadImage(for: attachments[indexPath.row])
        
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let attachment = attachments[indexPath.row]
            deleteAttachment(attachment)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func doneAction() {
        if serviceGeodatabase.hasLocalEdits() {
            // Show progress HUD.
            UIApplication.shared.showProgressHUD(message: "Applying edits")
            serviceGeodatabase.applyEdits { [weak self] (featureTableEditResults: [AGSFeatureTableEditResult]?, error: Error?) in
                // Dismiss progress HUD.
                UIApplication.shared.hideProgressHUD()
                guard let self = self else { return }
                if let featureTableEditResults = featureTableEditResults,
                   featureTableEditResults.first?.editResults.first?.completedWithErrors == false {
                    self.presentAlert(message: "Saved successfully!")
                } else if let error = error {
                    self.presentAlert(message: "Error while applying edits: \(error.localizedDescription)")
                }
                self.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func addAction() {
        guard let pngData = UIImage(named: "LocationDisplayOffIcon")?.pngData() else {
            return
        }
        UIApplication.shared.showProgressHUD(message: "Adding attachment")
        feature?.addAttachment(withName: "Attachment.png", contentType: "png", data: pngData) { [weak self] (attachment: AGSAttachment?, error: Error?) in
            UIApplication.shared.hideProgressHUD()
            guard let self = self else { return }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let attachment = attachment {
                // New attachments are added to the end.
                let indexPath = IndexPath(row: self.attachments.count, section: 0)
                // Update the model.
                self.attachments.append(attachment)
                // Update the table.
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }
    }
}
