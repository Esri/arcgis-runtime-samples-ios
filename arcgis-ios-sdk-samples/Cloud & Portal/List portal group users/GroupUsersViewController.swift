// Copyright 2017 Esri.
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

class GroupUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    private var portal: AGSPortal!
    private var portalGroup: AGSPortalGroup!
    private var portalUsers: [AGSPortalUser]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GroupUsersViewController", "GroupUserCell"]

        //automatic cell sizing for table view
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 104
        
        //initialize portal with AGOL
        self.portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        //load the portal group to be used
        self.loadPortalGroup()
    }
    
    private func loadPortalGroup() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Loading Portal Group")
        
        //query group based on owner and title
        let queryParams = AGSPortalQueryParameters(forGroupsWithOwner: "ArcGISRuntimeSDK", title: "Runtime Group")
        
        //find groups with using query params
        self.portal.findGroups(with: queryParams) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: Error?) in
            
            if let error = error {
                //show error
                self?.presentAlert(error: error)
            }
            else {
                
                //fetch users for the resulting group
                if let groups = resultSet?.results as? [AGSPortalGroup] , groups.count > 0 {
                    self?.portalGroup = groups[0]
                    self?.fetchGroupUsers()
                }
                else {
                    //show error that no groups found
                    self?.presentAlert(message: "No groups found")
                }
            }
        }
    }
    
    private func fetchGroupUsers() {
        //show progress hud
        SVProgressHUD.show(withStatus: "Fetching Users")
        
        //fetch users in group
        self.portalGroup.fetchUsers { [weak self] (users: [String]?, admins: [String]?, error: Error?) in
            
            if let error = error {
                //show error
                self?.presentAlert(error: error)
            }
            else {
                
                //if there are users in the group
                if let users = users , users.count > 0 {
                    self?.portalUsers = [AGSPortalUser]()
                    
                    //initialize AGSPortalUser objects with user names
                    for user in users {
                        let portalUser = AGSPortalUser(portal: self!.portal, username: user)
                        self?.portalUsers.append(portalUser)
                    }
                    
                    //load all users before populating into table view
                    self?.loadAllUsers()
                }
                else {
                    self?.presentAlert(message: "No users found")
                }
            }
        }
    }
    
    private func loadAllUsers() {
        //show progress hud
        SVProgressHUD.show(withStatus: "Loading User Data")
        
        //load user data
        AGSLoadObjects(self.portalUsers) { [weak self] (success) in
            if success {
                //dismiss hud
                SVProgressHUD.dismiss()
                
                //reload table view
                self?.tableView.reloadData()
            }
            else {
                self?.presentAlert(message: "Error while loading users data")
            }
        }
    }

    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.portalUsers?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupUserCell", for: indexPath) as! GroupUserCell
        
        let portalUser = self.portalUsers[indexPath.row]
        cell.portalUser = portalUser
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Runtime Group"
    }
}
