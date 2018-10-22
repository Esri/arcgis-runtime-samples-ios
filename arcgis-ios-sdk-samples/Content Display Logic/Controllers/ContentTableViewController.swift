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
        }
    }

    var searchEngine: SampleSearchEngine?
    
    private var expandedRowIndex: Int = -1
    
    private var bundleResourceRequest: NSBundleResourceRequest?
    private var downloadProgressView: DownloadProgressView?
    
    private var downloadProgressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize download progress view
        let downloadProgressView = DownloadProgressView()
        downloadProgressView.delegate = self
        self.downloadProgressView = downloadProgressView
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
        view.endEditing(true)
        
        let sample = displayedSamples[indexPath.row]
        
        //download on demand resources
        if !sample.dependencies.isEmpty {
        
            let bundleResourceRequest = NSBundleResourceRequest(tags: Set(sample.dependencies))
            self.bundleResourceRequest = bundleResourceRequest
            
            //conditionally begin accessing to know if we need to show download progress view or not
            bundleResourceRequest.conditionallyBeginAccessingResources { [weak self] (isResourceAvailable: Bool) in
                DispatchQueue.main.async {
                    
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
            bundleResourceRequest?.endAccessingResources()
            
            //show view controller
            showSample(indexPath: indexPath, sample: sample)
        }
    }
    
    func downloadResource(for sample: Sample, at indexPath:IndexPath) {
        
        guard let bundleResourceRequest = bundleResourceRequest else {
            return
        }
        
        //show download progress view
        downloadProgressView?.show(withStatus: "Just a moment while we download data for this sample...", progress: 0)
        
        //add an observer to update the progress in download progress view
        downloadProgressObservation = bundleResourceRequest.progress.observe(\.fractionCompleted, changeHandler: {[weak self] (progress, change) in
            
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                if let progressFraction = self.bundleResourceRequest?.progress.fractionCompleted {
                    self.downloadProgressView?.updateProgress(progress: CGFloat(progressFraction), animated: true)
                }
            }
        })
        
        //begin
        bundleResourceRequest.beginAccessingResources { [weak self] (error: Error?) in
            
            guard let self = self else {
                return
            }
            
            //in main thread
            DispatchQueue.main.async {
                
                //remove observation
                self.downloadProgressObservation = nil
                
                //dismiss download progress view
                self.downloadProgressView?.dismiss()
                
                if let error = error {
                    if let indexPath = self.tableView.indexPathForSelectedRow {
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    }
                    if (error as NSError).code != NSUserCancelledError {
                        self.presentAlert(message: "Failed to download raster resource :: \(error.localizedDescription)")
                    }
                }
                else {
                    
                    if self.bundleResourceRequest?.progress.isCancelled == false {
                        
                        //show view controller
                        self.showSample(indexPath: indexPath, sample: sample)
                    }
                }
            }
        }
    }
    
    private func showSample(indexPath: IndexPath, sample: Sample) {
        
        //expand the selected cell
        updateExpandedRow(indexPath, collapseIfSelected: false)
        
        let storyboard = UIStoryboard(name: sample.storyboardName, bundle: .main)
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = sample.name
        
        //must use the presenting controller when opening from search results or else splitViewController will be nil
        let presentingController: UIViewController? = searchEngine != nil ? presentingViewController : self
            
        let navController = UINavigationController(rootViewController: controller)
        if #available(iOS 11.0, *) {
            //don't use large titles on samples
            controller.navigationItem.largeTitleDisplayMode = .never
        }
        
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
        updateExpandedRow(IndexPath(row: sender.tag, section: 0), collapseIfSelected: true)
    }
    
    private func updateExpandedRow(_ indexPath:IndexPath, collapseIfSelected:Bool) {
        //if same row selected then hide the detail view
        if indexPath.row == expandedRowIndex {
            if collapseIfSelected {
                expandedRowIndex = -1
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            else {
                return
            }
        }
        else {
            //get the two cells and update
            let previouslyExpandedIndexPath = IndexPath(row: expandedRowIndex, section: 0)
            expandedRowIndex = indexPath.row
            tableView.reloadRows(at: [previouslyExpandedIndexPath, indexPath], with: .fade)
        }
    }

}

//MARK: - DownloadProgressViewDelegate
extension ContentTableViewController: DownloadProgressViewDelegate {

    func downloadProgressViewDidCancel(downloadProgressView: DownloadProgressView) {
        guard let bundleResourceRequest = bundleResourceRequest else {
            return
        }
        bundleResourceRequest.progress.cancel()
        bundleResourceRequest.endAccessingResources()
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
