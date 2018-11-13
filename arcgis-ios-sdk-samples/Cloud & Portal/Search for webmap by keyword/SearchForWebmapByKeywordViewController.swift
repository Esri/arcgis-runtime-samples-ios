//
// Copyright 2017 Esri.
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
//

import UIKit
import ArcGIS

class SearchForWebmapByKeywordViewController: UICollectionViewController {
    
    private var portal: AGSPortal?
    private var resultPortalItems: [AGSPortalItem] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var lastQueryCancelable: AGSCancelable?
    
    // strong reference needed for iOS 10
    private var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register to be notified about authentication challenges
        AGSAuthenticationManager.shared().delegate = self

        // create the portal
        portal = AGSPortal(url: URL(string: "https://arcgis.com")!, loginRequired: false)
    
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SearchForWebmapByKeywordViewController", "WebMapCell", "WebMapViewController"]
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if searchController == nil {
            addSearchController()
        }
    }
    
    private func addSearchController() {
        
        // create the search controller
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        // send search query updates to the results controller
        searchController.searchResultsUpdater = self
        // retain a strong reference for iOS 10
        self.searchController = searchController
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        // set the color of "Cancel" text
        searchBar.tintColor = .white
        
        // embed the search bar under the title in the navigation bar
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        // find the text field to customize its appearance
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            // set the color of the insertion cursor
            textfield.tintColor = UIColor.darkText
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 12
                backgroundview.clipsToBounds = true
            }
        }
        
    }
    
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
 
    private func startWebMapSearch(query: String) {
        
        // if the last search hasn't returned yet, cancel it
        lastQueryCancelable?.cancel()
        
        // webmaps authored prior to July 2nd, 2014 are not supported - so search only from that date to the current time
        let date1 = dateFormatter.date(from: "July 2, 2014")!
        let dateString = "uploaded:[000000\(Int(date1.timeIntervalSince1970)) TO 000000\(Int(Date().timeIntervalSince1970))]"
        
        // create query parameters looking for items of type .webMap and
        // with our keyword and date string
        let queryParams = AGSPortalQueryParameters(forItemsOf: .webMap, withSearch: "\(query) AND \(dateString)")
        lastQueryCancelable = portal?.findItems(with: queryParams) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: Error?) in
            if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    print(error.localizedDescription)
                }
            }
            else {
                //if our results are an array of portal items, set it on our web maps collection ViewController
                if let portalItems = resultSet?.results as? [AGSPortalItem] {
                    self?.resultPortalItems = portalItems
                }
                else {
                    self?.resultPortalItems = []
                }
            }
        }
    }

    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? WebMapViewController,
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row {
            controller.portalItem = resultPortalItems[selectedIndex]
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultPortalItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! WebMapCell
        let portalItem = resultPortalItems[indexPath.row]
        
        cell.titleLabel.text = portalItem.title
        cell.ownerLabel.text = portalItem.owner
        
        // imageview border
        cell.thumbnail.layer.borderColor = UIColor.darkGray.cgColor
        cell.thumbnail.layer.borderWidth = 1
        
        // date label
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        cell.timerLabel.text = dateFormatter.string(from: portalItem.modified!)
        
        if let image = portalItem.thumbnail?.image {
            cell.thumbnail.image = image
        }
        else {
            cell.thumbnail.image = UIImage(named: "Placeholder")
            portalItem.thumbnail?.load(completion: {[weak self] (error: Error?) -> Void in
                if let error = error {
                    print("Error downloading thumbnail :: \(error.localizedDescription)")
                }
                else {
                    self?.collectionView.reloadItems(at: [indexPath])
                }
            })
        }
        
        return cell
    }
    
}

extension SearchForWebmapByKeywordViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !query.isEmpty {
            startWebMapSearch(query: query)
        }
        else {
            lastQueryCancelable?.cancel()
            resultPortalItems = []
        }
    }
    
}


extension SearchForWebmapByKeywordViewController: AGSAuthenticationManagerDelegate {
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        
        // if a challenge is received, then the portal item is not fully public and cannot be displayed
        
        // don't present this challenge
        challenge.cancel()
        
        if let mapController = navigationController?.topViewController as? WebMapViewController {
            // stop attempts at map loading
            mapController.mapView.map = nil
            
            // close the view controller
            navigationController?.popViewController(animated: true)
        }
        
        // notify the user
        presentAlert(message: "Web map access denied")
    }
    
}
