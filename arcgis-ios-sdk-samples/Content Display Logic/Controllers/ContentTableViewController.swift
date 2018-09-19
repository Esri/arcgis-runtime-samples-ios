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

class ContentTableViewController: UITableViewController {
    
    /// The samples to display in the table. Searching adjusts this value
    var displayedSamples = [Sample](){
        didSet{
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    /// All samples that could be displayed in the table
    var allSamples = [Sample](){
        didSet{
            displayedSamples = allSamples
            searchEngine = SampleSearchEngine(samples: allSamples)
        }
    }
    private var expandedRowIndex:Int = -1
    
    var containsSearchResults = false
    private var bundleResourceRequest:NSBundleResourceRequest!
    private var downloadProgressView:DownloadProgressView!
    
    var searchEngine: SampleSearchEngine?
    
    // strong reference needed for iOS 10
    var filterSearchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize download progress view
        downloadProgressView = DownloadProgressView()
        downloadProgressView.delegate = self
        
        if !containsSearchResults{
            addFilterSearchController()
        }
    }
    
    private func addFilterSearchController(){
        
        // ensure that the search results are interactable
        definesPresentationContext = true
        
        // create the search controller
        let searchController = UISearchController(searchResultsController:nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        // send search query updates to the results controller
        searchController.searchResultsUpdater = self
        // retain a strong reference for iOS 10
        self.filterSearchController = searchController
        
        let searchBar = searchController.searchBar
        searchBar.placeholder = "Filter"
        searchBar.autocapitalizationType = .none
        // set the color of "Cancel" text
        searchBar.tintColor = .white
        
        if #available(iOS 11.0, *) {
            // embed the search bar under the title in the navigation bar
            navigationItem.searchController = searchController
            
            // find the text field to customize its appearance
            if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                // set the color of the insertion cursor
                textField.tintColor = .darkText
                if let backgroundview = textField.subviews.first {
                    backgroundview.backgroundColor = .white
                    backgroundview.layer.cornerRadius = 12
                    backgroundview.clipsToBounds = true
                }
            }
            
        } else {
            // embed the search bar in the title area of the navigation bar
            navigationItem.titleView = searchBar
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedSamples.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ContentTableCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ContentTableCell

        let sample = displayedSamples[indexPath.row]
        cell.titleLabel.text = sample.name
        
        if self.expandedRowIndex == indexPath.row {
            cell.detailLabel.text = sample.description
        }
        else {
            cell.detailLabel.text = nil
        }
        
        cell.infoButton.addTarget(self, action: #selector(ContentTableViewController.expandCell(_:)), for: .touchUpInside)
        cell.infoButton.tag = indexPath.row

        cell.backgroundColor = .clear
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //hide keyboard if visible
        self.view.endEditing(true)
        
        let sample = displayedSamples[indexPath.row]
        
        //download on demand resources
        if !sample.dependencies.isEmpty {
        
            self.bundleResourceRequest = NSBundleResourceRequest(tags: Set(sample.dependencies))
            
            //conditionally begin accessing to know if we need to show download progress view or not
            self.bundleResourceRequest.conditionallyBeginAccessingResources { [weak self] (isResourceAvailable: Bool) in
                DispatchQueue.main.sync {
                    
                    //if resource is already available then simply show the sample
                    if isResourceAvailable {
                        self?.showSample(indexPath: indexPath, sample: sample)
                    }
                    //else download the resource
                    else {
                        self?.downloadResource(for: sample, at: indexPath)
                    }
                }
            }
        }
        else {
            //clear bundleResourceRequest
            self.bundleResourceRequest?.endAccessingResources()
            
            //show view controller
            self.showSample(indexPath: indexPath, sample: sample)
        }
    }
    
    func downloadResource(for sample: Sample, at indexPath:IndexPath) {
        
        //show download progress view
        self.downloadProgressView.show(withStatus: "Just a moment while we download data for this sample...", progress: 0)
        
        //add an observer to update the progress in download progress view
        self.bundleResourceRequest.progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: nil)
        
        //begin
        self.bundleResourceRequest.beginAccessingResources { [weak self] (error: Error?) in
            
            //in main thread
            DispatchQueue.main.sync {
                
                guard let strongSelf = self else {
                    return
                }
                
                //remove observer
                strongSelf.bundleResourceRequest?.progress.removeObserver(strongSelf, forKeyPath: #keyPath(Progress.fractionCompleted))
                
                //dismiss download progress view
                strongSelf.downloadProgressView.dismiss()
                
                if let error = error {
                    if let indexPath = strongSelf.tableView.indexPathForSelectedRow {
                        strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                    }
                    if (error as NSError).code != NSUserCancelledError {
                        SVProgressHUD.showError(withStatus: "Failed to download raster resource :: \(error.localizedDescription)")
                    }
                }
                else {
                    
                    if !strongSelf.bundleResourceRequest.progress.isCancelled {
                        
                        //show view controller
                        strongSelf.showSample(indexPath: indexPath, sample: sample)
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
    
    func showSample(indexPath: IndexPath, sample: Sample) {
        
        //expand the selected cell
        self.updateExpandedRow(indexPath, collapseIfSelected: false)
        
        let storyboard = UIStoryboard(name: sample.storyboardName, bundle: .main)
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = sample.name
        
        //must use the presenting controller when opening from search results or else splitViewController will be nil
        let presentingController: UIViewController? = containsSearchResults ? presentingViewController : self
            
        let navController = UINavigationController(rootViewController: controller)
        
        //add the button on the left on the detail view controller
        controller.navigationItem.leftBarButtonItem = presentingController?.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
        
        //present the sample view controller
        presentingController?.showDetailViewController(navController, sender: self)
        
        //create and setup the info button
        let infoBBI = SourceCodeBarButtonItem()
        infoBBI.readmeURL = sample.readmeURL
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
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            else {
                return
            }
        }
        else {
            //get the two cells and update
            let previouslyExpandedIndexPath = IndexPath(row: self.expandedRowIndex, section: 0)
            self.expandedRowIndex = indexPath.row
            tableView.reloadRows(at: [previouslyExpandedIndexPath, indexPath], with: .fade)
        }
    }

}

//MARK: - DownloadProgressViewDelegate
extension ContentTableViewController: DownloadProgressViewDelegate {

    func downloadProgressViewDidCancel(downloadProgressView: DownloadProgressView) {
        self.bundleResourceRequest.progress.cancel()
        self.bundleResourceRequest?.endAccessingResources()
    }

}

extension ContentTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchEngine = searchEngine else {
            return
        }
        
        if searchController.isActive,
            let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !query.isEmpty{
            displayedSamples = searchEngine.sortedSamples(matching: query)
        }
        else{
            displayedSamples = allSamples
        }
    }
    
}
