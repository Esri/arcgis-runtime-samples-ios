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

class ListUsersInGroupVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    private var portal: AGSPortal!
    private var portalGroup: AGSPortalGroup!
    private var portalUsers: [AGSPortalUser]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListUsersInGroupVC", "UserTableViewCell"]
        
        //for self-sizing table view cells
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 104
        
        //initialize AGOL portal
        self.portal = AGSPortal.ArcGISOnlineWithLoginRequired(false)
        
        //fetch the group from the portal
        self.fetchPortalGroup()
    }
    
    private func fetchPortalGroup() {
        //create a query parameters object for the group to fetch by providing the owner and title of the group
        let queryParams = AGSPortalQueryParameters(forGroupsWithOwner: "lahub_admin", title: "City of Los Angeles Open Data")
        
        //find the group using the query parameters
        self.portal.findGroupsWithQueryParameters(queryParams) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                if let groups = resultSet?.results as? [AGSPortalGroup] where groups.count > 0 {
                    //if a group is found, fetch the users in that group
                    self?.portalGroup = groups[0]
                    self?.fetchGroupUsers()
                }
                else {
                    SVProgressHUD.showErrorWithStatus("No groups found", maskType: .Gradient)
                }
            }
        }
    }
    
    private func fetchGroupUsers() {
        
        //fetch users in the group
        self.portalGroup.fetchUsersWithCompletion { [weak self] (usernames: [String]?, admins: [String]?, error: NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                if let usernames = usernames where usernames.count > 0, let weakSelf = self {
                    //if usernames are found create AGSPortalUser objects for each
                    let portalUsers = weakSelf.portalUsersFor(usernames)
                    
                    //load the portal user objects
                    weakSelf.loadPortalUsers(portalUsers)
                }
                else {
                    SVProgressHUD.showErrorWithStatus("No users found", maskType: .Gradient)
                }
            }
        }
    }
    
    //create an AGSPortalUser object for each username
    private func portalUsersFor(usernames: [String]) -> [AGSPortalUser] {
        
        var portalUsers = [AGSPortalUser]()
        
        for username in usernames {
            let portalUser = AGSPortalUser(portal: self.portal, username: username)
            portalUsers.append(portalUser)
        }
        
        return portalUsers
    }
    
    private func loadPortalUsers(portalUsers: [AGSPortalUser]) {
        //load the portal users
        AGSLoadObjects(portalUsers, { [weak self] (succeed: Bool) in
            
            //on completion update the list and reload table view
            self?.portalUsers = portalUsers
            self?.tableView.reloadData()
        })
    }
    
    //load the loadableImage and update the image view for the specified index path
    private func loadThumbnail(thumbnail: AGSLoadableImage, forIndexPath indexPath: NSIndexPath) {
    
        thumbnail.loadWithCompletion({ [weak self] (error: NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                //if the cell is visible update the image
                if let cell = self?.tableView.cellForRowAtIndexPath(indexPath) as? UserTableViewCell {
                    cell.thumbnailImageView.image = thumbnail.image
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.portalUsers?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("UserTableViewCell") as! UserTableViewCell
        
        //portal user at index path
        let portalUser = self.portalUsers[indexPath.row]
        
        //title label
        cell.titleLabel.text = portalUser.fullName
        
        //description label
        cell.descriptionLabel.text = portalUser.userDescription
        
        cell.thumbnailImageView.layer.cornerRadius = 40
        
        //thumbnail
        if let thumbnail = portalUser.thumbnail {
            if thumbnail.image != nil {
                cell.thumbnailImageView.image = thumbnail.image
            }
            else {
                self.loadThumbnail(thumbnail, forIndexPath: indexPath)
            }
        }
        else {
            cell.thumbnailImageView.image = UIImage(named: "Placeholder")
        }
        
        return cell
    }

}
