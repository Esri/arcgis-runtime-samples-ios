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

class ContentCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    @IBOutlet private var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    /// The categories to display in the collection view.
    var categories: [Category] = [] {
        didSet {
            // add search only after setting categories to ensure that the samples are available
            addSearchController()
        }
    }
    
    private func addSearchController() {
        // create the view controller for displaying the search results
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
        let allSamples = categories.flatMap { $0.samples }
        searchResultsController.allSamples = allSamples
        searchResultsController.searchEngine = SampleSearchEngine(samples: allSamples)
        
        // create the search controller
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.obscuresBackgroundDuringPresentation = true
        // Setting hidesNavigationBarDuringPresentation to false causes issues on iOS 13 - 13.1.2,
        // so we hide the navigation bar during search.
        searchController.hidesNavigationBarDuringPresentation = true
        // send search query updates to the results controller
        searchController.searchResultsUpdater = searchResultsController
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        
        if #available(iOS 13, *) {
            // Do nothing, on iOS 13 the settings below have no effect.
        } else {
            // This code is required to make the search bar look decent on iOS 12
            // This does not work on iOS 13, where the search bar looks different.
            // Different meaning - not as good as iOS 12 looks like with this fix,
            // but at least acceptable and a bit better than what it would look like
            // on 12 without this fix.
            
            // set the color of "Cancel" text
            searchBar.tintColor = .white
            
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
        
        // embed the search bar under the title in the navigation bar
        navigationItem.searchController = searchController
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        let category = categories[indexPath.item]
        
        //mask to bounds
        cell.layer.masksToBounds = false
        
        //name
        cell.nameLabel.text = category.name.uppercased()
        
        //icon
        let image = UIImage(named: "\(category.name)_icon")
        cell.iconImageView.image = image
        
        //background image
        let bgImage = UIImage(named: "\(category.name)_bg")
        cell.backgroundImageView.image = bgImage
        
        //cell shadow
        cell.layer.cornerRadius = 5
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //hide keyboard if visible
        view.endEditing(true)
        
        let category = categories[indexPath.item]
        let controller = storyboard!.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
        controller.allSamples = category.samples
        controller.title = category.name
        show(controller, sender: self)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewSize = collectionView.bounds.inset(by: collectionView.safeAreaInsets).size
        
        let spacing: CGFloat = 10
        //first try for 3 items in a row
        var width = (collectionViewSize.width - 4 * spacing) / 3
        if width < 150 {
            //if too small then go for 2 in a row
            width = (collectionViewSize.width - 3 * spacing) / 2
        }
        return CGSize(width: width, height: width)
    }
}
