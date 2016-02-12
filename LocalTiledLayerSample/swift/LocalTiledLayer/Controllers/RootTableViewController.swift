/*
Copyright 2015 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit

class RootTableViewController: UITableViewController {

    //Array to hold the paths of tile packages in the app bundle
    var tilePackagesFromBundle:[String]!
    
    //Array to hold the paths of tile packages, if exists, in the documents directory
    var tilePackagesFromDocuments = [String]()
    
    var selectedTilePackage:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //gets all the paths for the files with extension ".tpk" in the app bundle
        self.tilePackagesFromBundle = NSBundle.mainBundle().pathsForResourcesOfType("tpk", inDirectory: nil) 
        
        //procedure to get all the tile packages from the documents directory, if any
        let ext = "tpk"
        let fileManager = NSFileManager.defaultManager()
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0]
        do {
            let contents = try fileManager.contentsOfDirectoryAtPath(documentsDirectory)
            for filename in contents {
                if (filename as NSString).pathExtension == ext {
                    self.tilePackagesFromDocuments.append(filename)
                }
            }
        }
        catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //One section for the app bundle tile packages and the other one for the ones from documents directory
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in each section depending on the respective array counts.
        if section == 0 {
            if self.tilePackagesFromBundle.count > 0 {
                return self.tilePackagesFromBundle.count
            }
            else {
                return 1
            }
        }
        else {
            if self.tilePackagesFromDocuments.count > 0 {
                return self.tilePackagesFromDocuments.count
            }
            else {
                return 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "From App Bundle"
        }
        else {
            return "From Documents Directory";
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
        
        // Configure the cell...
        if indexPath.section == 0 {
            if self.tilePackagesFromBundle.count > 0 {
                //retrieves the file name from the array object according to the present cell index.
                //gets only the file name without the extension for display.
                let fileName = ((self.tilePackagesFromBundle[indexPath.row] as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
                cell.textLabel?.text = fileName;
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                cell.textLabel?.text = "None found"
            }
        }
            
        else {
            if self.tilePackagesFromDocuments.count > 0 {
                //retrieves the file name from the array object according to the present cell index.
                //gets only the file name without the extension for display.
                let fileName = ((self.tilePackagesFromDocuments[indexPath.row] as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
                cell.textLabel?.text = fileName
                cell.accessoryType = .DisclosureIndicator
            }   
            else {
                cell.textLabel?.text = "None found"
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
        
        var tilePackage:String!
        if indexPath.section == 0 {
            if self.tilePackagesFromBundle.count > 0 {
                tilePackage = self.tilePackagesFromBundle[indexPath.row]
            }
            else  {
                return
            }
        }
            
        else {
            if self.tilePackagesFromDocuments.count > 0 {
                tilePackage = self.tilePackagesFromDocuments[indexPath.row]
            }
            else {
                return
            }
        }
        
        self.selectedTilePackage = tilePackage
        self.performSegueWithIdentifier("SegueLocalTiledLayerVC", sender: self)
    }

    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SegueLocalTiledLayerVC" {
            let controller = segue.destinationViewController as! LocalTiledLayerViewController
            controller.tilePackage = (self.selectedTilePackage as NSString).lastPathComponent
            controller.title = ((self.selectedTilePackage as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
        }
    }

}
