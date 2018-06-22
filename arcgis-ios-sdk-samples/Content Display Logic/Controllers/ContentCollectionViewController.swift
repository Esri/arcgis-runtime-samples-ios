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

class ContentCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CustomSearchHeaderViewDelegate {

    @IBOutlet private var collectionView:UICollectionView!
    @IBOutlet private var collectionViewFlowLayout:UICollectionViewFlowLayout!
    
    private var headerView:CustomSearchHeaderView!
    
    var nodesArray:[Node]!
    private var transitionSize:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        //hide suggestions
        self.hideSuggestions()
        
        self.populateTree()
    }
    
    func populateTree() {
        
        let path = Bundle.main.path(forResource: "ContentPList", ofType: "plist")
        let content = NSArray(contentsOfFile: path!)
        self.nodesArray = self.populateNodesArray(content! as [AnyObject])
        
        self.collectionView?.reloadData()
    }
    
    func populateNodesArray(_ array:[AnyObject]) -> [Node] {
        var nodesArray = [Node]()
        for object in array {
            let node = self.populateNode(object as! [String:AnyObject])
            nodesArray.append(node)
        }
        return nodesArray
    }
    
    func populateNode(_ dict:[String:AnyObject]) -> Node {
        let node = Node()
        if let displayName = dict["displayName"] as? String {
            node.displayName = displayName
        }
        if let descriptionText = dict["descriptionText"] as? String {
            node.descriptionText = descriptionText
        }
        if let storyboardName = dict["storyboardName"] as? String {
            node.storyboardName = storyboardName
        }
        if let children = dict["children"] as? [AnyObject] {
            node.children = self.populateNodesArray(children)
        }
        if let dependency = dict["dependency"] as? [String] {
            node.dependency.append(contentsOf: dependency)
        }
        return node
    }
    
    
    //MARK: - Suggestions related
    
    func showSuggestions() {
//        if !self.isSuggestionsTableVisible() {
            self.collectionView.performBatchUpdates({ [weak self] () -> Void in
                (self?.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize = CGSize(width: self!.collectionView.bounds.width, height: self!.headerView.expandedViewHeight)
            }, completion: nil)
            
            //show suggestions
//        }
    }
    
    func hideSuggestions() {
//        if self.isSuggestionsTableVisible() {
            self.collectionView.performBatchUpdates({ [weak self] () -> Void in
                (self?.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize = CGSize(width: self!.collectionView.bounds.width, height: self!.headerView.shrinkedViewHeight)
            }, completion: nil)
            
            //hide suggestions
//        }
    }

    //TODO: implement this
//    func isSuggestionsTableVisible() -> Bool {
//        return (self.headerView?.suggestionsTableHeightConstraint?.constant == 0 ? false : true) ?? false
//    }
    
    //MARK: - samples lookup by name
    
    func nodesByDisplayNames(_ names:[String]) -> [Node] {
        var nodes = [Node]()
        for node in self.nodesArray {
            let children = node.children
            if let matchingNodes = children?.filter({ return names.contains($0.displayName) }) {
                nodes.append(contentsOf: matchingNodes)
            }
        }
        return nodes
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.nodesArray?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CategoryCell
        
        let node = self.nodesArray[indexPath.item]
        
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

    //supplementary view as search bar
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if self.headerView == nil {
            self.headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionHeaderView", for: indexPath) as! CustomSearchHeaderView
            self.headerView.delegate = self
        }
        return self.headerView
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //hide keyboard if visible
        self.view.endEditing(true)
        
        let node = self.nodesArray[indexPath.item]
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "ContentTableViewController") as! ContentTableViewController
        controller.nodesArray = node.children
        controller.title = node.displayName
        self.navigationController?.show(controller, sender: self)
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

    //MARK: - CustomSearchHeaderViewDelegate
    
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
    
    func customSearchHeaderViewWillHideSuggestions(_ customSearchHeaderView: CustomSearchHeaderView) {
        self.hideSuggestions()
    }
    
    func customSearchHeaderViewWillShowSuggestions(_ customSearchHeaderView: CustomSearchHeaderView) {
        self.showSuggestions()
    }
}
