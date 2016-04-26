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

protocol IdentifyResultsVCDelegate:class {
    
    func identifyResultsViewController(identifyResultsViewController:IdentifyResultsViewController, didSelectGeoElementAtIndex index:Int)
    func identifyResultsViewControllerWantsToClose(identifyResultsViewController:IdentifyResultsViewController)
}

class IdentifyResultsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView:UICollectionView!
    @IBOutlet var statusLabel:UILabel!
    
    weak var delegate:IdentifyResultsVCDelegate?
    
    var geoElements:[AGSGeoElement]! {
        didSet {
            //update the status label
            self.statusLabel?.text = "1 of \(self.geoElements.count)"
            
            self.collectionView?.reloadData()
            
            //reset collection view content offset
            self.collectionView.contentOffset.x = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.geoElements?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ResultCell", forIndexPath: indexPath) as! GeoElementCell
        
        cell.geoElement = self.geoElements[indexPath.row]
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    //MARK: - Actions
    
    @IBAction func closeAction() {
        self.delegate?.identifyResultsViewControllerWantsToClose(self)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Scrolling
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageWidth = self.collectionView.bounds.width
        let currentPage = Int(ceil(self.collectionView.contentOffset.x/pageWidth) + 1)
        
        self.statusLabel.text = "\(currentPage) of \(self.geoElements.count)"
        
        //notify delegate
        self.delegate?.identifyResultsViewController(self, didSelectGeoElementAtIndex: currentPage-1)
    }
}
