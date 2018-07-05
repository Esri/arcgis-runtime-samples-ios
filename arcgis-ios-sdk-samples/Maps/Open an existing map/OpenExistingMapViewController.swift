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

class OpenExistingMapViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let itemURL1 = "https://www.arcgis.com/home/item.html?id=2d6fa24b357d427f9c737774e7b0f977"
    private let itemURL2 = "https://www.arcgis.com/home/item.html?id=01f052c8995e4b9e889d73c3e210ebe3"
    private let itemURL3 = "https://www.arcgis.com/home/item.html?id=92ad152b9da94dee89b9e387dfe21acd"
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var blurView:UIVisualEffectView!
    @IBOutlet private weak var tableParentView:UIView!
    @IBOutlet private weak var tableView:UITableView!
    
    private var map:AGSMap!
    private var titles = ["Housing with Mortgages", "USA Tapestry Segmentation", "Geology of United States"]
    private var imageNames = ["OpenExistingMapThumbnail1", "OpenExistingMapThumbnail2", "OpenExistingMapThumbnail3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(url: URL(string: itemURL1)!)
        
        self.mapView.map = self.map
                
        //UI setup
        //add rounded corners for table's parent view
        self.tableParentView.layer.cornerRadius = 10
        
        //self sizing cells
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OpenExistingMapViewController"]
    }
    
    //MARK: - Actions
    
    @IBAction private func mapsAction() {
        //toggle table view
        self.blurView.isHidden = !self.blurView.isHidden
    }
    
    //MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingMapCell", for: indexPath)
        cell.backgroundColor = .clear
        
        cell.textLabel?.text = self.titles[indexPath.row]
        cell.imageView?.image = UIImage(named: self.imageNames[indexPath.row])!
        cell.imageView?.contentMode = UIViewContentMode.scaleAspectFill
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedPortalItemURL:String
        switch indexPath.row {
        case 1:
            selectedPortalItemURL = self.itemURL2
        case 2:
            selectedPortalItemURL = self.itemURL3
        default:
            selectedPortalItemURL = self.itemURL1
        }
        self.map = AGSMap(url: URL(string: selectedPortalItemURL)!)
        self.mapView.map = self.map
        
        //toggle table view
        self.blurView.isHidden = !self.blurView.isHidden
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
}
