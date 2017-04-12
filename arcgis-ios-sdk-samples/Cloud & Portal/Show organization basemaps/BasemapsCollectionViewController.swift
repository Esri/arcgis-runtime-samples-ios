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

import UIKit
import ArcGIS

protocol BasemapsCollectionVCDelegate: class {
    
    func basemapsCollectionViewController(_ basemapsCollectionViewController: BasemapsCollectionViewController, didSelectBasemap basemap: AGSBasemap)
    
    func basemapsCollectionViewControllerDidCancel(_ basemapsCollectionViewController: BasemapsCollectionViewController)
}

class BasemapsCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!
    
    var portal: AGSPortal!
    private var basemapHelper = BasemapHelper.shared
    
    weak var delegate: BasemapsCollectionVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //content size for modal presentation on ipad
        self.preferredContentSize = CGSize(width: 500, height: 400)
        
        //fetch basemaps from the portal using helper class
        self.basemapHelper.fetchBasemaps(from: self.portal) { [weak self] (error: Error?) in
            self?.collectionView.reloadData()
        }
    }

    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //if there are more basemaps available to download, keep an extra cell
        if let _ = self.basemapHelper.resultSet?.nextQueryParameters {
            return self.basemapHelper.basemaps.count + 1
        }
        else {
            return self.basemapHelper.basemaps?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //special cell to provide feedback that more basemaps are available
        if indexPath.row == self.basemapHelper.basemaps.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlusCell", for: indexPath)
            
            cell.layer.borderColor = UIColor.gray.cgColor
            cell.layer.borderWidth = 1
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BasemapCell", for: indexPath) as! BasemapCell
            
            //portal item at index
            cell.portalItem = self.basemapHelper.basemaps[indexPath.item]
            
            //styling
            cell.layer.borderColor = UIColor.gray.cgColor
            cell.layer.borderWidth = 1
            
            return cell
        }
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //if the special plus cell is selected, fetch more basemaps from the portal
        if indexPath.row == self.basemapHelper.basemaps.count {
            self.basemapHelper.fetchMoreBasemaps { [weak self] (error: Error?) in
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                else {
                    self?.collectionView.reloadData()
                }
            }
        }
        else {
            
            //else notify delegate with the selected basemap
            let basemap = AGSBasemap(item: self.basemapHelper.basemaps[indexPath.row])
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (_: UIViewControllerTransitionCoordinatorContext) in
            self.collectionView.performBatchUpdates(nil, completion: nil)
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
