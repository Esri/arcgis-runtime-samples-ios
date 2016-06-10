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
import ArcGIS

class MapPackagesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MapPackageCellDelegate {
    
    @IBOutlet var tableView:UITableView!
    
    private var mapPackagesInBundle:[AGSMobileMapPackage]!
    private var mapPackagesInDocumentsDir:[AGSMobileMapPackage]!
    
    private var selectedRowIndexPath:NSIndexPath!
    private var selectedMap:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        self.fetchMapPackages()
        
        AGSRequestConfiguration.globalConfiguration().debugLogRequests = true
        AGSRequestConfiguration.globalConfiguration().debugLogResponses = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchMapPackages() {
        //load map packages from the bundle
        let bundleMMPKPaths = NSBundle.mainBundle().pathsForResourcesOfType("mmpk", inDirectory: nil)
        
        //create map packages from the paths
        self.mapPackagesInBundle = [AGSMobileMapPackage]()
        
        for path in bundleMMPKPaths {
            let mapPackage = AGSMobileMapPackage(path: path)
            self.mapPackagesInBundle.append(mapPackage)
        }
        
        //load map packages from the documents directory
        //added using iTunes
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let subpaths = NSFileManager.defaultManager().subpathsAtPath(path[0])!
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", ".*mmpk$")
        let mmpks = subpaths.filter({ (objc) -> Bool in
            return predicate.evaluateWithObject(objc)
        })
        let documentMMPKPaths = mmpks.map({ (name:String) -> String in
            return "\(path[0])/\(name)"
        })
        
        //create map packages from the paths
        self.mapPackagesInDocumentsDir = [AGSMobileMapPackage]()
        
        for path in documentMMPKPaths {
            let mapPackage = AGSMobileMapPackage(path: path)
            self.mapPackagesInDocumentsDir.append(mapPackage)
        }
        
        self.tableView.reloadData()
    }
    
    //MARK : - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.mapPackagesInBundle?.count ?? 0
        }
        else {
            return self.mapPackagesInDocumentsDir?.count ?? 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MapPackageCell") as! MapPackageCell
        
        var mapPackage:AGSMobileMapPackage
        
        if indexPath.section == 0 {
            mapPackage = self.mapPackagesInBundle[indexPath.row]
        }
        else {
            mapPackage = self.mapPackagesInDocumentsDir[indexPath.row]
        }
        
        cell.mapPackage = mapPackage
        cell.isCollapsed = self.selectedRowIndexPath != indexPath
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "From the bundle" : "From the documents directory"
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //collapse previously expanded cell
        var indexPathsArray = [NSIndexPath]()
        indexPathsArray.append(indexPath)
        
        if self.selectedRowIndexPath != nil {
            if self.selectedRowIndexPath == indexPath {
                //collapse
                self.selectedRowIndexPath = nil
            }
            else {
                indexPathsArray.append(self.selectedRowIndexPath)
                self.selectedRowIndexPath = indexPath
            }
        }
        else {
            self.selectedRowIndexPath = indexPath
        }
        
        tableView.reloadRowsAtIndexPaths(indexPathsArray, withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    //MARK: - MapPackageCellDelegate
    
    func mapPackageCell(mapPackageCell: MapPackageCell, didSelectMap map: AGSMap) {
        self.selectedMap = map
        self.performSegueWithIdentifier("MobileMapVCSegue", sender: self)
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MobileMapVCSegue" {
            let controller = segue.destinationViewController as! MobileMapViewController
            controller.map = self.selectedMap
            
            var mapPackage:AGSMobileMapPackage!
            
            if self.selectedRowIndexPath.section == 0 {
                mapPackage = self.mapPackagesInBundle[self.selectedRowIndexPath.row]
            }
            else {
                mapPackage = self.mapPackagesInDocumentsDir[self.selectedRowIndexPath.row]
            }
            
            controller.locatorTask = mapPackage.locatorTask
            controller.title = mapPackage.item?.title
        }
    }
}
