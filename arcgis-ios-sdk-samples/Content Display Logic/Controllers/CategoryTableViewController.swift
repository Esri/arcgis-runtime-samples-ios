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
import Firebase

class CategoryTableViewController: UITableViewController {
    /// The samples to display in the table. Searching adjusts this value
    var displayedSamples = [Sample]() {
        didSet {
            guard isViewLoaded else { return }
            updateDataSource()
        }
    }
    
    /// All samples that could be displayed in the table
    var allSamples = [Sample]() {
        didSet {
            displayedSamples = allSamples
        }
    }
    
    var searchEngine: SampleSearchEngine?
    /// Tracks whether or not it is the favorites category.
    var isFavoritesCategory = false
    
    /// The dynamic data source.
    private var dataSource: UITableViewDiffableDataSource<Int, String>!
    
    private var expandedRowIndexPaths: Set<IndexPath> = []
    
    private var bundleResourceRequest: NSBundleResourceRequest?
    private var downloadProgressView: DownloadProgressView?
    
    private var downloadProgressObservation: NSKeyValueObservation?
    
    /// Returns the index path for the given sample.
    func indexPath(for sample: Sample) -> IndexPath {
        IndexPath(row: displayedSamples.firstIndex(of: sample)!, section: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize download progress view.
        let downloadProgressView = DownloadProgressView()
        downloadProgressView.delegate = self
        self.downloadProgressView = downloadProgressView
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, _ in
            let sample = self.displayedSamples[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContentTableCell", for: indexPath) as! ContentTableCell
            cell.titleLabel.text = sample.name
            cell.detailLabel.text = sample.description
            cell.isExpanded = expandedRowIndexPaths.contains(indexPath)
            return cell
        })
        updateDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedSample = nil
        if isFavoritesCategory {
            displayedSamples = displayedSamples.filter(\.isFavorite)
        }
    }
    
    // MARK: Sample Selection
    
    /// The currently selected sample.
    private(set) var selectedSample: Sample? {
        didSet {
            guard selectedSample != oldValue else { return }
            selectedSampleDidChange()
        }
    }
    
    /// Responds to the selected sample being changed.
    private func selectedSampleDidChange() {
        if let sample = selectedSample {
            // Google Analytics select sample event.
            Analytics.logEvent("select_sample", parameters: [
                AnalyticsParameterContentType: sample.name
            ])
            
            let indexPathForSample = indexPath(for: sample)
            if tableView.indexPathForSelectedRow != indexPathForSample {
                tableView.selectRow(at: indexPathForSample, animated: true, scrollPosition: .top)
            }
            if !sample.dependencies.isEmpty {
                // Download on demand resources.
                let bundleResourceRequest = NSBundleResourceRequest(tags: Set(sample.dependencies))
                bundleResourceRequest.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
                self.bundleResourceRequest = bundleResourceRequest
                
                // Conditionally begin accessing to know if we need to show download progress view or not.
                bundleResourceRequest.conditionallyBeginAccessingResources { [weak self] (isResourceAvailable: Bool) in
                    DispatchQueue.main.async {
                        // If resource is already available then simply show the sample.
                        if isResourceAvailable {
                            self?.showSample(sample)
                        }
                        // Else download the resource.
                        else {
                            self?.downloadResource(for: sample)
                        }
                    }
                }
            } else {
                if let bundleResourceRequest = bundleResourceRequest {
                    bundleResourceRequest.endAccessingResources()
                    self.bundleResourceRequest = nil
                }
                
                showSample(sample)
            }
        } else {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Hide keyboard if visible.
        view.endEditing(true)
        
        selectedSample = displayedSamples[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        toggleExpansion(at: indexPath)
    }
    
    // MARK: - helpers
    
    /// Update the data source if the table has changed.
    private func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([.zero])
        let items = displayedSamples
            .map(\.name)
        snapshot.appendItems(items)
        dataSource.apply(snapshot)
    }
    
    private func downloadResource(for sample: Sample) {
        guard let bundleResourceRequest = bundleResourceRequest else {
            return
        }
        
        // Show download progress view.
        downloadProgressView?.show(withStatus: "Just a moment while we download data for this sample...", progress: 0)
        
        // Add an observer to update the progress in download progress view.
        downloadProgressObservation = bundleResourceRequest.progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
            DispatchQueue.main.async {
                self?.downloadProgressView?.updateProgress(progress: CGFloat(progress.fractionCompleted), animated: true)
            }
        }
        
        // Begin
        bundleResourceRequest.beginAccessingResources { [weak self] (error: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Remove observation.
                self.downloadProgressObservation = nil
                
                // Dismiss download progress view.
                self.downloadProgressView?.dismiss()
                
                if let error = error {
                    self.bundleResourceRequest = nil
                    self.selectedSample = nil
                    if (error as NSError).code != NSUserCancelledError {
                        self.presentAlert(message: "Failed to download raster resource :: \(error.localizedDescription)")
                    }
                } else {
                    if self.bundleResourceRequest?.progress.isCancelled == false {
                        // Show view controller.
                        self.showSample(sample)
                    }
                }
            }
        }
    }
    
    private func showSample(_ sample: Sample) {
        let storyboard = UIStoryboard(name: sample.storyboardName, bundle: .main)
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = sample.name
        
        // Must use the presenting controller when opening from search results or else splitViewController will be nil.
        let presentingController: UIViewController? = searchEngine != nil ? presentingViewController : self
        
        // If the sample is selected from search results, log the search term.
        if let searchController = presentingViewController?.navigationItem.searchController,
           searchController.isActive,
           let searchTerm = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !searchTerm.isEmpty {
            // Google Analytics search event.
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: searchTerm
            ])
        }
        
        let navController = UINavigationController(rootViewController: controller)
        
        // Don't use large titles on samples.
        controller.navigationItem.largeTitleDisplayMode = .never
        
        // Add the button on the left on the detail view controller.
        controller.navigationItem.leftBarButtonItem = presentingController?.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
        
        // Present the sample view controller.
        presentingController?.showDetailViewController(navController, sender: self)
        
        // Create and setup the info button.
        let sourceCodeBarButtonItem = SourceCodeBarButtonItem()
        sourceCodeBarButtonItem.readmeURL = sample.readmeURL
        sourceCodeBarButtonItem.navController = navController
        // Create and setup the favorite button.
        let favoritesBarButtonItem = FavoritesBarButtonItem(sample: sample)
        controller.navigationItem.rightBarButtonItems = [sourceCodeBarButtonItem, favoritesBarButtonItem]
    }
    
    private func toggleExpansion(at indexPath: IndexPath) {
        // If same row selected then hide the detail view.
        if expandedRowIndexPaths.contains(indexPath) {
            expandedRowIndexPaths.remove(indexPath)
        } else {
            // Get the two cells and update.
            expandedRowIndexPaths.update(with: indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension CategoryTableViewController: DownloadProgressViewDelegate {
    func downloadProgressViewDidCancel(_ downloadProgressView: DownloadProgressView) {
        guard let bundleResourceRequest = bundleResourceRequest else {
            return
        }
        bundleResourceRequest.progress.cancel()
        self.bundleResourceRequest = nil
        self.selectedSample = nil
    }
}

extension CategoryTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchEngine = searchEngine else {
            return
        }
        
        // Do not preserve cell expansion when loading new results.
        expandedRowIndexPaths.removeAll()
        
        if searchController.isActive,
           let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !query.isEmpty {
            displayedSamples = searchEngine.sortedSamples(matching: query)
        } else {
            displayedSamples = allSamples
        }
    }
}
