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

protocol WebMapsCollectionViewControllerDelegate: AnyObject {
    
    func webMapsCollectionVC(_ webMapsCollectionVC:WebMapsCollectionViewController, didSelectWebMap webMap:AGSPortalItem)
}

class WebMapsCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var collectionView:UICollectionView!
    
    var portalItems:[AGSPortalItem]! {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    weak var delegate:WebMapsCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.portalItems?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! WebMapCell
        let portalItem = self.portalItems[indexPath.row]
        
        cell.portalItem = portalItem
        
        return cell
    }
    
    //MARK: - Collection view delegates
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let portalItem = self.portalItems[indexPath.row]
        self.delegate?.webMapsCollectionVC(self, didSelectWebMap: portalItem)
    }
}
