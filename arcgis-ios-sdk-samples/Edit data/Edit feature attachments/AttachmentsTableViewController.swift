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
    
    weak var feature: AGSArcGISFeature?
    private var attachments: [AGSAttachment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadAttachments()
    }
    
    private func loadAttachments() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Loading attachments")
        
        feature?.fetchAttachments { [weak self] (attachments: [AGSAttachment]?, error: Error?) in
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            }
            
            self.attachments = attachments ?? []
            self.tableView.reloadData()
        }
    }
    
    private func deleteAttachment(_ attachment: AGSAttachment) {
        feature?.delete(attachment) { [weak self] (error: Error?) in
            if let error = error {
                print(error)
            } else {
                self?.loadAttachments()
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentCell", for: indexPath)
        
        let attachment = attachments[indexPath.row]
        cell.textLabel?.text = attachment.name
        
        cell.imageView?.image = UIImage(named: "CloudDownload", in: AGSBundle(), compatibleWith: nil)
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.autoresizingMask = []
        cell.imageView?.clipsToBounds = true
        if attachment.hasFetchedData {
            downloadAndSetAttachmentImageForCell(cell, at: indexPath)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        downloadAndSetAttachmentImageForCell(cell, at: indexPath)
        cell.setSelected(false, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let attachment = attachments[indexPath.row]
            deleteAttachment(attachment)
        }
    }
    
    private func downloadAndSetAttachmentImageForCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let attachment = attachments[indexPath.row]
        
        if !attachment.hasFetchedData {
            SVProgressHUD.show(withStatus: "Downloading attachment")
        }
        
        attachment.fetchData { (data: Data?, error: Error?) in
            
            SVProgressHUD.dismiss()
            
            if let error = error {
                print(error)
            } else if let data = data,
                let image = UIImage(data: data) {
                cell.imageView?.image = image
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func doneAction() {
        
        guard let table = feature?.featureTable as? AGSServiceFeatureTable else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Applying edits")
        
        table.applyEdits { [weak self] (result, error) in
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            }
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func addAction() {
        
        guard let pngData = UIImage(named: "LocationDisplayOffIcon")?.pngData() else {
            return
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Adding attachment")
        
        feature?.addAttachment(withName: "Attachment.png", contentType: "png", data: pngData) { [weak self] (attachment: AGSAttachment?, error: Error?) in
            
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.loadAttachments()
            }
        }
    }

}
