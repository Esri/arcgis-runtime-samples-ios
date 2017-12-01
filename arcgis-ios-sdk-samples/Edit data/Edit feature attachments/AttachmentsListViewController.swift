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

class AttachmentsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIBarPositioningDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var feature:AGSArcGISFeature!
    private var attachments:[AGSAttachment]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadAttachments()
    }
    
    func applyEdits() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Applying edits", maskType: .gradient)
        
        (self.feature.featureTable as! AGSServiceFeatureTable).applyEdits { [weak self] (result, error) -> Void in
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                SVProgressHUD.showInfo(withStatus: "Apply edits finished successfully", maskType: .gradient)
                self?.loadAttachments()
            }
        }
    }
    
    func loadAttachments() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Loading attachments", maskType: .gradient)
        
        self.feature.fetchAttachments { [weak self] (attachments:[AGSAttachment]?, error:Error?) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                self?.attachments = attachments
                self?.tableView.reloadData()
            }
        }
    }
    
    func deleteAttachment(_ attachment:AGSAttachment) {
        self.feature.delete(attachment) { [weak self] (error:Error?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                print("Attachment deleted")
                self?.applyEdits()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attachments?.count ?? 0
    }
    
    //MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentCell")!
        
        let attachment = self.attachments[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = attachment.name
        
        cell.imageView?.image = UIImage(named: "ArcGIS.bundle/CloudDownload")
        cell.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        cell.imageView?.autoresizingMask = UIViewAutoresizing()
        cell.imageView?.clipsToBounds = true
        if attachment.hasFetchedData {
            self.setImageForCell(cell, at: indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let cell = tableView.cellForRow(at: indexPath)!
         self.setImageForCell(cell, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let attachment = self.attachments[(indexPath as NSIndexPath).row]
            self.deleteAttachment(attachment)
        }
    }
    
    func setImageForCell(_ cell:UITableViewCell, at indexPath:IndexPath) {
        let attachment = self.attachments[(indexPath as NSIndexPath).row]
        attachment.fetchData { (data:Data?, error:Error?) -> Void in
            if let error = error {
                print(error)
            }
            else if let data = data {
                let image = UIImage(data: data)
                cell.imageView?.image = image
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAction() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Adding attachment", maskType: .gradient)
        
        let data = UIImagePNGRepresentation(UIImage(named: "LocationDisplayOffIcon")!)!
        self.feature.addAttachment(withName: "Attachment.png", contentType: "png", data: data) { [weak self] (attachment:AGSAttachment?, error:Error?) -> Void in
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                self?.applyEdits()
            }
        }
    }
    
    //MARK: - UIBarPositioningDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
