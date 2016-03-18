//
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

protocol TilePackagesListVCDelegate:class {
    func tilePackagesListViewController(tilePackagesListViewController:TilePackagesListViewController, didSelectTPKWithPath path:String)
}

class TilePackagesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    
    weak var delegate:TilePackagesListVCDelegate?
    
    private var bundleTPKPaths:[String]!
    private var documentTPKPaths:[String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchTilePackagesInBundle()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchTilePackagesInBundle() {
        self.bundleTPKPaths = NSBundle.mainBundle().pathsForResourcesOfType("tpk", inDirectory: nil)
        self.tableView.reloadData()
        
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let subpaths = NSFileManager.defaultManager().subpathsAtPath(path[0])
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", ".*tpk$")
        let tpks = subpaths?.filter({ (objc) -> Bool in
            return predicate.evaluateWithObject(objc)
        })
        self.documentTPKPaths = tpks?.map({ (name:String) -> String in
            return "\(path[0])/\(name)"
        })
    }

    //MARK : - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.bundleTPKPaths?.count ?? 0
        }
        else {
            return self.documentTPKPaths?.count ?? 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TilePackageCell")!
        
        if indexPath.section == 0 {
            cell.textLabel?.text = self.extractName(self.bundleTPKPaths[indexPath.row])
        }
        else {
            cell.textLabel?.text = self.extractName(self.documentTPKPaths[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "From the bundle" : "From the documents directory"
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var path = ""
        if indexPath.section == 0 {
            path = self.bundleTPKPaths[indexPath.row]
        }
        else {
            path = self.documentTPKPaths[indexPath.row]
        }
        self.delegate?.tilePackagesListViewController(self, didSelectTPKWithPath: path)
    }
    
    func extractName(path:String) -> String {
        var index = path.rangeOfString("/", options: .BackwardsSearch, range: nil, locale: nil)?.startIndex
        index = index?.advancedBy(1)
        let name = path.substringFromIndex(index!)
        return name
    }
}
