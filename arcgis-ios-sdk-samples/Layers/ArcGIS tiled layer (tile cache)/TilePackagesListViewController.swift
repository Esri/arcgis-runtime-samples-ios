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
    func tilePackagesListViewController(_ tilePackagesListViewController:TilePackagesListViewController, didSelectTPKWithPath path:String)
}

class TilePackagesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView:UITableView!
    
    weak var delegate:TilePackagesListVCDelegate?
    
    private var bundleTPKPaths:[String]!
    private var documentTPKPaths:[String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fetch tile packages from bundle and document directory
        self.fetchTilePackages()
    }
    
    func fetchTilePackages() {
        self.bundleTPKPaths = Bundle.main.paths(forResourcesOfType: "tpk", inDirectory: nil)
        self.tableView.reloadData()
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let subpaths = FileManager.default.subpaths(atPath: path[0])
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", ".*tpk$")
        let tpks = subpaths?.filter { (objc) -> Bool in
            return predicate.evaluate(with: objc)
        }
        self.documentTPKPaths = tpks?.map { (name:String) -> String in
            return "\(path[0])/\(name)"
        }
    }
    
    //MARK : - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.bundleTPKPaths?.count ?? 0
        }
        else {
            return self.documentTPKPaths?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TilePackageCell", for: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = self.extractName(fromPath: self.bundleTPKPaths[indexPath.row])
        }
        else {
            cell.textLabel?.text = self.extractName(fromPath: self.documentTPKPaths[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "From the bundle" : "From the documents directory"
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var path = ""
        if (indexPath as NSIndexPath).section == 0 {
            path = self.bundleTPKPaths[indexPath.row]
        }
        else {
            path = self.documentTPKPaths[indexPath.row]
        }
        self.delegate?.tilePackagesListViewController(self, didSelectTPKWithPath: path)
    }
    
    func extractName(fromPath path:String) -> String {
        guard var index = path.range(of: "/", options: .backwards, range: nil, locale: nil)?.lowerBound else {
            return ""
        }
        index = path.index(after: index)
        let name = path[index...]
        return String(name)
    }
}

