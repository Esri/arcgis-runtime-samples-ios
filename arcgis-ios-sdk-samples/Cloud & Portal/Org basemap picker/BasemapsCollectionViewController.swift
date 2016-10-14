//
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
import ArcGIS

protocol BasemapsCollectionVCDelegate: class {
    
    func basemapsCollectionViewController(basemapsCollectionViewController: BasemapsCollectionViewController, didSelectBasemap basemap: AGSBasemap)
    func basemapsCollectionViewControllerDidCancel(basemapsCollectionViewController: BasemapsCollectionViewController)
}

class BasemapsCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var portalURLString: String!
    var anonymousUser: Bool = true
    
    private var portal: AGSPortal!
    private var basemapsGroup: AGSPortalGroup!
    private var basemaps = [AGSPortalItem]()
    private var resultSet: AGSPortalQueryResultSet!
    
    weak var delegate: BasemapsCollectionVCDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadPortal()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadPortal() {
        self.portal = AGSPortal(URL: NSURL(string: self.portalURLString)!, loginRequired: !self.anonymousUser)
        self.portal.loadWithCompletion { [weak self] (error: NSError?) in
            if let error = error {
                print(error)
            }
            else {
                self?.fetchBasemapsGroup()
            }
        }
    }
    
    private func fetchBasemapsGroup() {
        if let queryString = self.portal.portalInfo?.basemapGalleryGroupQuery {
            let queryParameters = AGSPortalQueryParameters(query: queryString)
            self.portal.findGroupsWithQueryParameters(queryParameters, completion: { (resultSet: AGSPortalQueryResultSet?, error: NSError?) in
                if let error = error {
                    print(error)
                }
                else {
                    if let basemapsGroup = resultSet?.results?[0] as? AGSPortalGroup {
                        self.basemapsGroup = basemapsGroup
                        let queryParameters = AGSPortalQueryParameters(forItemsInGroup: "\(self.basemapsGroup.groupID!)")
                        self.fetchBasemaps(queryParameters)
                    }
                }
            })
        }
    }
    
    private func fetchBasemaps(queryParameters: AGSPortalQueryParameters) {
        queryParameters.limit = 5
        self.portal.findItemsWithQueryParameters(queryParameters) { (resultSet: AGSPortalQueryResultSet?, error: NSError?) in
            if let error = error {
                print(error)
            }
            else {
                if let basemaps = resultSet?.results as? [AGSPortalItem] {
                    self.loadBasemaps(basemaps)
                    self.resultSet = resultSet!
                }
            }
        }
    }
    
    private func loadBasemaps(basemaps: [AGSPortalItem]) {
        AGSLoadObjects(basemaps) { (succeed: Bool) in
            //reload collection view
            self.basemaps.appendContentsOf(basemaps)
            self.collectionView.reloadData()
        }
    }
    
    private func loadMoreBasemaps() {
        if let queryParameters = self.resultSet.nextQueryParameters {
            self.fetchBasemaps(queryParameters)
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let _ = self.resultSet?.nextQueryParameters {
            return self.basemaps.count + 1
        }
        else {
            return self.basemaps.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.row == self.basemaps.count {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PlusCell", forIndexPath: indexPath)
            
            cell.layer.borderColor = UIColor.grayColor().CGColor
            cell.layer.borderWidth = 1
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BasemapCell", forIndexPath: indexPath) as! BasemapCell
            
            let portalItem = self.basemaps[indexPath.item]
            
            cell.label.text = portalItem.title
            
            //image
            if let image = portalItem.thumbnail?.image {
                cell.imageView.image = image
            }
            else {
                cell.imageView.image = nil
                portalItem.thumbnail?.loadWithCompletion({ (error: NSError?) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? BasemapCell {
                            cell.imageView.image = portalItem.thumbnail?.image
                        }
                    }
                })
            }
            
            cell.layer.borderColor = UIColor.grayColor().CGColor
            cell.layer.borderWidth = 1
            
            return cell
        }
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == self.basemaps.count {
            self.loadMoreBasemaps()
        }
        else {
            let basemap = AGSBasemap(item: self.basemaps[indexPath.row])
            self.delegate?.basemapsCollectionViewController(self, didSelectBasemap: basemap)
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func cancelAction() {
        self.delegate?.basemapsCollectionViewControllerDidCancel(self)
    }
    
    //
    //Cell resize logic for device rotation
    //
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let collectionViewSize = collectionView.bounds.size
        let defaultCellSize:CGFloat = 140
        let defaultCellSpacing:CGFloat = 10
        let cellSizePlusSpacing = defaultCellSize + defaultCellSpacing
        
        //find out number of possible items in one row
        let n = floor((collectionViewSize.width - defaultCellSpacing) / (cellSizePlusSpacing))
        
        //extra space per cell
        let extra = (collectionViewSize.width - (n * cellSizePlusSpacing) - defaultCellSpacing) / n
        
        return CGSize(width: defaultCellSize + extra, height: defaultCellSize + extra)
    }
    
    //MARK: -
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (_: UIViewControllerTransitionCoordinatorContext) in
            self.collectionView.performBatchUpdates(nil, completion: nil)
            }, completion: nil)
    }
}
