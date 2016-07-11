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

class AttachmentsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var feature:AGSArcGISFeature!
    private var attachments:[AGSAttachment]!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadAttachments()
    }
    
    func applyEdits() {
        (self.feature.featureTable as! AGSServiceFeatureTable).applyEditsWithCompletion({ [weak self] (result, error) -> Void in
            if let error = error {
                print(error)
            }
            else {
                print("Apply edits finished successfully")
                self?.loadAttachments()
            }
        })
    }
    
    func loadAttachments() {
        self.feature.fetchAttachmentsWithCompletion { [weak self] (attachments:[AGSAttachment]?, error:NSError?) in
            if let error = error {
                print(error)
            }
            else {
                self?.attachments = attachments
                self?.tableView.reloadData()
            }
        }
    }
    
    func deleteAttachment(attachment:AGSAttachment) {
        self.feature.deleteAttachment(attachment, completion: { [weak self] (error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                print("Attachment deleted")
                self?.applyEdits()
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attachments?.count ?? 0
    }
    
    //MARK: - Table view delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AttachmentCell")!
        
        let attachment = self.attachments[indexPath.row]
        cell.textLabel?.text = attachment.name
        
        cell.imageView?.image = UIImage(named: "ArcGIS.bundle/CloudDownload")
        cell.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        cell.imageView?.autoresizingMask = .None
        cell.imageView?.clipsToBounds = true
        if attachment.hasFetchedData {
            self.setImage(indexPath)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.setImage(indexPath)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let attachment = self.attachments[indexPath.row]
            self.deleteAttachment(attachment)
        }
    }
    
    func setImage(indexPath:NSIndexPath) {
        let attachment = self.attachments[indexPath.row]
        attachment.fetchDataWithCompletion { [weak self] (data:NSData?, error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else if let weakSelf = self, data = data {
                let image = UIImage(data: data)
                let cell = weakSelf.tableView.cellForRowAtIndexPath(indexPath)!
                if weakSelf.tableView.visibleCells.contains(cell) {
                    cell.imageView?.image = image
                }
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func cancelAction() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addAction() {
        let data = UIImagePNGRepresentation(UIImage(named: "LocationDisplayOffIcon")!)!
        self.feature.addAttachmentWithName("Attachment.png", contentType: "png", data: data) { [weak self] (attachment:AGSAttachment?, error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.applyEdits()
            }
        }
    }
}
