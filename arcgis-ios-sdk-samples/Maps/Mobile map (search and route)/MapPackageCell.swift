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

protocol MapPackageCellDelegate:class {
    
    func mapPackageCell(mapPackageCell:MapPackageCell, didSelectMap map:AGSMap)
}


class MapPackageCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var collectionView:UICollectionView!
    
    @IBOutlet var collectionViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var collectionViewTopConstraint:NSLayoutConstraint!
    
    weak var delegate:MapPackageCellDelegate?
    
    var isCollapsed = true {
        didSet {
            isCollapsed ? self.collapseCell() : self.expandCell()
        }
    }
    
    var mapPackage:AGSMobileMapPackage! {
        didSet {
            self.loadMapPackage()
        }
    }
    
    func loadMapPackage() {
        self.mapPackage.loadWithCompletion({ [weak self] (error:NSError?) in
            if let error = error {
                //error
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                //update title label
                self?.titleLabel.text = self?.mapPackage.item?.title
                
                self?.collectionView.reloadData()
            }
        })
    }
    
    func expandCell() {
        self.collectionViewTopConstraint.constant = 8
        self.collectionViewHeightConstraint.constant = 110
    }
    
    func collapseCell() {
        self.collectionViewTopConstraint.constant = 0
        self.collectionViewHeightConstraint.constant = 0
    }

    //MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mapPackage?.maps.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MobileMapCell", forIndexPath: indexPath)
        
        //label
        let label = cell.viewWithTag(11) as! UILabel
        label.text = "Map \(indexPath.item+1)"
        
        //border
        cell.layer.borderColor = UIColor.blackColor().CGColor
        cell.layer.borderWidth = 1
        
        //search image view
        let searchImageView = cell.viewWithTag(12) as! UIImageView
        searchImageView.hidden = (self.mapPackage.locatorTask == nil)
        
        let map = self.mapPackage.maps[indexPath.item]
        //route image view
        let routeImageView = cell.viewWithTag(13) as! UIImageView
        routeImageView.hidden = (map.transportationNetworks.count == 0)
        
        //thumbnail
        let imageView = cell.viewWithTag(14) as! UIImageView
        imageView.image = map.item?.thumbnail?.image
        imageView.layer.borderColor = UIColor.grayColor().CGColor
        imageView.layer.borderWidth = 1
        
        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.mapPackageCell(self, didSelectMap: self.mapPackage.maps[indexPath.item])
    }
}
