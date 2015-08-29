// Copyright 2015 Esri.
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

class BookmarksListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    
    //list of bookmarks
    var bookmarks:AGSList!
    
    //private property to store selection action for table cell
    private var selectAction:((AGSViewpoint) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //executed for tableview row selection
    func setSelectAction(action : ((AGSViewpoint) -> Void)) {
        self.selectAction = action
    }
    
    //MARK: - TableView data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bookmarks?.count ?? 0
    }
    
    //MARK: - TableView delegates
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BookmarkCell") as! UITableViewCell
        cell.backgroundColor = UIColor.clearColor()
        //get the respective bookmark
        let bookmark = self.bookmarks[UInt(indexPath.row)] as! AGSBookmark
        //assign the bookmark's name as the title for the cell
        cell.textLabel?.text = bookmark.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let bookmark = self.bookmarks[UInt(indexPath.row)] as! AGSBookmark
        //execute the closure if it exists
        if self.selectAction != nil {
            self.selectAction(bookmark.viewpoint!)
        }
    }
    
}
