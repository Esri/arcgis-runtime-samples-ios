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

class ContentTableViewController: UITableViewController, CustomSearchHeaderViewDelegate, DownloadProgressViewDelegate {

    private lazy var __once: () = { [weak self] in
            self?.animateTable()
        }()

    var nodesArray:[Node]!
    private var expandedRowIndex:Int = -1
    
    private var headerView:CustomSearchHeaderView!
    var containsSearchResults = false
    private var bundleResourceRequest:NSBundleResourceRequest!
    private var downloadProgressView:DownloadProgressView!

    var token: Int = 0
    
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
        
        //initialize download progress view
        self.downloadProgressView = DownloadProgressView()
        self.downloadProgressView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //animate the table only the first time the view appears
        _ = self.__once
    }
    
    func animateTable() {
        //call reload data and wait for it to finish
        //before accessing the visible cells
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        
        //will be animating only the visible cells
        let visibleCells = self.tableView.visibleCells
        
        //counter for the for loop
        var index = 0
        
        //loop through each visible cell
        //and set the starting transform and then animate to identity
        for cell in visibleCells {
            
            //starting position
            cell.transform = CGAffineTransform(translationX: self.tableView.bounds.width, y: 0)
            
            //last position with animation
            UIView.animate(withDuration: 0.5, delay: 0.1 * Double(index), usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                
                cell.transform = CGAffineTransform.identity
                
            }, completion: nil)
            
            //increment counter
            index = index + 1
        }
    }
    
    func nodesByDisplayNames(_ names:[String]) -> [Node] {
        var nodes = [Node]()
        let matchingNodes = self.nodesArray.filter({ return names.contains($0.displayName) })
        nodes.append(contentsOf: matchingNodes)
        return nodes
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nodesArray?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ContentTableCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ContentTableCell

        let node = self.nodesArray[indexPath.row]
        cell.titleLabel.text = node.displayName
        
        if self.expandedRowIndex == indexPath.row {
            cell.detailLabel.text = node.descriptionText
        }
        else {
            cell.detailLabel.text = nil
        }
        
        cell.infoButton.addTarget(self, action: #selector(ContentTableViewController.expandCell(_:)), for: UIControlEvents.touchUpInside)
        cell.infoButton.tag = indexPath.row

        cell.backgroundColor = .clear
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //hide keyboard if visible
        self.view.endEditing(true)
        
        let node = self.nodesArray[indexPath.row]
        
        //download on demand resources
        if node.dependency.count > 0 {
            
            self.bundleResourceRequest = NSBundleResourceRequest(tags: Set(node.dependency))
            
            //conditionally begin accessing to know if we need to show download progress view or not
            self.bundleResourceRequest.conditionallyBeginAccessingResources { [weak self] (isResourceAvailable: Bool) in
                DispatchQueue.main.sync {
                    
                    //if resource is already available then simply show the sample
                    if isResourceAvailable {
                        self?.showSample(indexPath: indexPath, node: node)
                    }
                    //else download the resource
                    else {
                        self?.downloadResource(for: node, at: indexPath)
                    }
                }
            }
        }
        else {
            //clear bundleResourceRequest
            self.bundleResourceRequest?.endAccessingResources()
            
            //show view controller
            self.showSample(indexPath: indexPath, node: node)
        }
    }
    
    func downloadResource(for node:Node, at indexPath:IndexPath) {
        
        //show download progress view
        self.downloadProgressView.show(withStatus: "Just a moment while we download data for this sample...", progress: 0)
        
        //add an observer to update the progress in download progress view
        self.bundleResourceRequest.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        
        //begin
        self.bundleResourceRequest.beginAccessingResources { [weak self] (error: Error?) in
            
            //in main thread
            DispatchQueue.main.sync {
                
                guard let strongSelf = self else {
                    return
                }
                
                //remove observer
                strongSelf.bundleResourceRequest?.progress.removeObserver(strongSelf, forKeyPath: "fractionCompleted")
                
                //dismiss download progress view
                strongSelf.downloadProgressView.dismiss()
                
                if let error = error {
                    SVProgressHUD.showError(withStatus: "Failed to download raster resource :: \(error.localizedDescription)")
                }
                else {
                    
                    if !strongSelf.bundleResourceRequest.progress.isCancelled {
                        
                        //show view controller
                        strongSelf.showSample(indexPath: indexPath, node: node)
                    }
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted" {
            DispatchQueue.main.async { [weak self] in
                self?.downloadProgressView?.updateProgress(progress: CGFloat(self!.bundleResourceRequest.progress.fractionCompleted), animated: true)
            }
        }
    }
    
    func showSample(indexPath: IndexPath, node: Node) {
        
        //expand the selected cell
        self.updateExpandedRow(indexPath, collapseIfSelected: false)
        
        let storyboard = UIStoryboard(name: node.storyboardName, bundle: Bundle.main)
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = node.displayName
        let navController = UINavigationController(rootViewController: controller)
        
        self.splitViewController?.showDetailViewController(navController, sender: self)
        
        //add the button on the left on the detail view controller
        if let splitViewController = self.view.window?.rootViewController as? UISplitViewController {
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
        
        //create the info button and
        //assign the readme url
        let infoBBI = SourceCodeBarButtonItem()
        infoBBI.folderName = node.displayName
        infoBBI.navController = navController
        controller.navigationItem.rightBarButtonItem = infoBBI
    }
    
    @objc func expandCell(_ sender:UIButton) {
        self.updateExpandedRow(IndexPath(row: sender.tag, section: 0), collapseIfSelected: true)
    }
    
    func updateExpandedRow(_ indexPath:IndexPath, collapseIfSelected:Bool) {
        //if same row selected then hide the detail view
        if indexPath.row == self.expandedRowIndex {
            if collapseIfSelected {
                self.expandedRowIndex = -1
                tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
            else {
                return
            }
        }
        else {
            //get the two cells and update
            let previouslyExpandedIndexPath = IndexPath(row: self.expandedRowIndex, section: 0)
            self.expandedRowIndex = indexPath.row
            tableView.reloadRows(at: [previouslyExpandedIndexPath, indexPath], with: UITableViewRowAnimation.fade)
        }
    }
    
    //MARK: - CustomSearchHeaderViewDelegate
    
    func customSearchHeaderViewWillShowSuggestions(_ customSearchHeaderView: CustomSearchHeaderView) {
        var headerViewFrame = self.headerView.frame
        headerViewFrame.size.height = customSearchHeaderView.expandedViewHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = self.headerView
        }, completion: nil)
    }
    
    func customSearchHeaderViewWillHideSuggestions(_ customSearchHeaderView: CustomSearchHeaderView) {
        var headerViewFrame = self.headerView.frame
        headerViewFrame.size.height = customSearchHeaderView.shrinkedViewHeight

        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = self.headerView
        }, completion: nil)
    }
    
    func customSearchHeaderView(_ customSearchHeaderView: CustomSearchHeaderView, didFindSamples sampleNames: [String]?) {
        if let sampleNames = sampleNames {
            let resultNodes = self.nodesByDisplayNames(sampleNames)
            if resultNodes.count > 0 {
                //show the results
                let controller = self.storyboard!.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
                controller.nodesArray = resultNodes
                controller.title = "Search results"
                controller.containsSearchResults = true
                self.navigationController?.show(controller, sender: self)
                return
            }
        }
        
        SVProgressHUD.showError(withStatus: "No match found")
        
    }
    
    //MARK: - DownloadProgressViewDelegate
    
    func downloadProgressViewDidCancel(downloadProgressView: DownloadProgressView) {
        self.bundleResourceRequest.progress.cancel()
        self.bundleResourceRequest?.endAccessingResources()
    }
}
