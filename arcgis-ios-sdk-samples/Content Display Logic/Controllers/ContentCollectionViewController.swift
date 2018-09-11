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

class CustomFlowLayout:UICollectionViewFlowLayout {
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

private let reuseIdentifier = "CategoryCell"

class ContentCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet private var collectionView:UICollectionView!
    @IBOutlet private var collectionViewFlowLayout:UICollectionViewFlowLayout!
    
    private var transitionSize:CGSize!
    
    var searchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        addSearchController()
    }
    
    private func addSearchController(){
        
        // create the view controller for displaying the search results
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let searchResultsController = storyboard.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
        searchResultsController.nodesArray = []
        searchResultsController.containsSearchResults = true
        searchResultsController.title = "Search"
        
        // create the search controller
        let searchController = UISearchController(searchResultsController:searchResultsController)
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        // send search query updates to the results controller
        searchController.searchResultsUpdater = searchResultsController
        self.searchController = searchController
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        // set the color of "Cancel" text
        searchBar.tintColor = .white
        
        // ensure that the search results appear beneath the navigation bar
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            // embed the search bar under the title in the navigation bar
            navigationItem.searchController = searchController
            
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
            
        } else {
            // embed the search bar in the title area of the navigation bar
            navigationItem.titleView = searchController.searchBar
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NodeManager.shared.categoryNodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CategoryCell
        
        let node = NodeManager.shared.categoryNodes[indexPath.item]
        
        //mask to bounds
        cell.layer.masksToBounds = false
        
        //name
        cell.nameLabel.text = node.displayName.uppercased()
        
        //icon
        let image = UIImage(named: "\(node.displayName)_icon")
        cell.iconImageView.image = image
        
        //background image
        let bgImage = UIImage(named: "\(node.displayName)_bg")
        cell.backgroundImageView.image = bgImage
        
        //cell shadow
        cell.layer.cornerRadius = 5
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //hide keyboard if visible
        self.view.endEditing(true)
        
        let node = NodeManager.shared.categoryNodes[indexPath.item]
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
        controller.nodesArray = node.children
        controller.title = node.displayName
        navigationController?.pushViewController(controller, animated: true)
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = self.itemSizeForCollectionViewSize(self.collectionView.bounds.size)
        
        return size
    }
    
    //MARK: - Transition
    
    //get the size of the new view to be transitioned to
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] (_: UIViewControllerTransitionCoordinatorContext) in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
        
    }
    
    //item width based on the width of the collection view
    func itemSizeForCollectionViewSize(_ size:CGSize) -> CGSize {
        //first try for 3 items in a row
        var width = (size.width - 4*10)/3
        if width < 150 {    //if too small then go for 2 in a row
            width = (size.width - 3*10)/2
        }
        return CGSize(width: width, height: width)
    }
    
}
