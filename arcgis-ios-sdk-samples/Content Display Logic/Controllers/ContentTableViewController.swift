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

class ContentTableViewController: UITableViewController, CustomSearchHeaderViewDelegate {

    var nodesArray:[Node]!
    private var expandedRowIndex:Int = -1
    
    private var headerView:CustomSearchHeaderView!
    var containsSearchResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 60
        
        if containsSearchResults {
            self.tableView.tableHeaderView?.removeFromSuperview()
            self.tableView.tableHeaderView = nil
        }
        else {
            self.headerView = self.tableView.tableHeaderView! as! CustomSearchHeaderView
            self.headerView.delegate = self
            self.headerView.hideSuggestionsTable()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func nodesByDisplayNames(names:[String]) -> [Node] {
        var nodes = [Node]()
        let matchingNodes = self.nodesArray.filter({ return names.contains($0.displayName) })
        nodes.appendContentsOf(matchingNodes)
        return nodes
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nodesArray?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = "ContentTableCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! ContentTableCell

        let node = self.nodesArray[indexPath.row]
        cell.titleLabel.text = node.displayName
        
        if self.expandedRowIndex == indexPath.row {
            cell.detailLabel.text = node.descriptionText
        }
        else {
            cell.detailLabel.text = nil
        }
        
        cell.infoButton.addTarget(self, action: #selector(ContentTableViewController.expandCell(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        cell.infoButton.tag = indexPath.row

        cell.backgroundColor = UIColor.clearColor()
        
        cell.layer.shadowColor = UIColor.lightGrayColor().CGColor
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowOpacity = 0.5
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //hide keyboard if visible
        self.view.endEditing(true)
        
        let node = self.nodesArray[indexPath.row]
        
        //expand the selected cell
        self.updateExpandedRow(indexPath, collapseIfSelected: false)
        
        let storyboard = UIStoryboard(name: node.storyboardName, bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = node.displayName
        let navController = UINavigationController(rootViewController: controller)
        
        self.splitViewController?.showDetailViewController(navController, sender: self)
        
        //add the button on the left on the detail view controller
        if let splitViewController = self.view.window?.rootViewController as? UISplitViewController {
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
        
        //create the info button and
        //assign the readme url
        let infoBBI = SourceCodeBarButtonItem()
        infoBBI.folderName = node.displayName
        infoBBI.navController = navController
        controller.navigationItem.rightBarButtonItem = infoBBI
    }
    
    func expandCell(sender:UIButton) {
        self.updateExpandedRow(NSIndexPath(forRow: sender.tag, inSection: 0), collapseIfSelected: true)
    }
    
    func updateExpandedRow(indexPath:NSIndexPath, collapseIfSelected:Bool) {
        //if same row selected then hide the detail view
        if indexPath.row == self.expandedRowIndex {
            if collapseIfSelected {
                self.expandedRowIndex = -1
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else {
                return
            }
        }
        else {
            //get the two cells and update
            let previouslyExpandedIndexPath = NSIndexPath(forRow: self.expandedRowIndex, inSection: 0)
            self.expandedRowIndex = indexPath.row
            tableView.reloadRowsAtIndexPaths([previouslyExpandedIndexPath, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    //MARK: - CustomSearchHeaderViewDelegate
    
    func customSearchHeaderViewWillShowSuggestions(customSearchHeaderView: CustomSearchHeaderView) {
        var headerViewFrame = self.headerView.frame
        headerViewFrame.size.height = customSearchHeaderView.expandedViewHeight
        
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = self.headerView
        }, completion: nil)
    }
    
    func customSearchHeaderViewWillHideSuggestions(customSearchHeaderView: CustomSearchHeaderView) {
        var headerViewFrame = self.headerView.frame
        headerViewFrame.size.height = customSearchHeaderView.shrinkedViewHeight

        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = self.headerView
        }, completion: nil)
    }
    
    func customSearchHeaderView(customSearchHeaderView: CustomSearchHeaderView, didFindSamples sampleNames: [String]?) {
        if let sampleNames = sampleNames {
            let resultNodes = self.nodesByDisplayNames(sampleNames)
            if resultNodes.count > 0 {
                //show the results
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ContentTableViewController") as! ContentTableViewController
                controller.nodesArray = resultNodes
                controller.title = "Search results"
                controller.containsSearchResults = true
                self.navigationController?.showViewController(controller, sender: self)
                return
            }
        }
        
        UIAlertView(title: "Error", message: "No match found", delegate: nil, cancelButtonTitle: "Ok").show()
        
    }
}
