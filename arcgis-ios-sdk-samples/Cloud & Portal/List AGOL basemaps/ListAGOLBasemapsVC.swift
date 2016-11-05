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

class ListAGOLBasemapsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    
    private var portal:AGSPortal!
    private var basemaps:[AGSBasemap]!
    private var defaultBasemap:AGSBasemap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListAGOLBasemapsVC"]
        
        //fetch basemaps
        self.fetchBasemaps()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func fetchBasemaps() {
        //instantiate portal with no login required
        self.portal = AGSPortal.ArcGISOnlineWithLoginRequired(false)
        
        //fetch basemaps from portal
        self.portal.fetchBasemapsWithCompletion { [weak self] (basemaps: [AGSBasemap]?, error: NSError?) in
            if let error = error {
                print(error)
            }
            else {
                //keep a reference to the default basemap 
                //as it will be highlighted in the list
                self?.defaultBasemap = self?.portal.portalInfo?.defaultBasemap
                
                self?.basemaps = basemaps!
                self?.collectionView.reloadData()
            }
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.basemaps?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BasemapCell", forIndexPath: indexPath) as! BasemapCell
        
        let basemap = self.basemaps[indexPath.item]
        
        cell.label.text = basemap.item?.title
        
        //image
        if let image = basemap.item?.thumbnail?.image {
            cell.imageView.image = image
        }
        else {
            cell.imageView.image = nil
            basemap.item?.thumbnail?.loadWithCompletion({ (error: NSError?) in
                if let error = error {
                    print(error)
                }
                else {
                    if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? BasemapCell {
                        cell.imageView.image = basemap.item?.thumbnail?.image
                    }
                }
            })
        }
        
        //change cell background if default basemap
        if self.defaultBasemap.name == basemap.item?.title {
            cell.label.backgroundColor = UIColor(red: 0, green: 122/255.0, blue: 1, alpha: 1)
            cell.label.textColor = UIColor.whiteColor()
        }
        else {
            cell.label.backgroundColor = UIColor.clearColor()
            cell.label.textColor = UIColor.blackColor()
        }
        
        //cell styling
        cell.layer.borderColor = UIColor.grayColor().CGColor
        cell.layer.borderWidth = 1
        
        return cell
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
