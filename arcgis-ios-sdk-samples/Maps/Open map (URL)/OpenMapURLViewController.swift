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

class OpenMapURLViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct MapAtURL {
        var title: String
        var image: UIImage
        var url: URL
    }
    
    let mapModels:[MapAtURL] = [
        MapAtURL(title: "Housing with Mortgages",
                 image: #imageLiteral(resourceName: "OpenMapURLThumbnail1"),
                 url: URL(string:"https://www.arcgis.com/home/item.html?id=2d6fa24b357d427f9c737774e7b0f977")!),
        MapAtURL(title: "USA Tapestry Segmentation",
                 image: #imageLiteral(resourceName: "OpenMapURLThumbnail2"),
                 url: URL(string:"https://www.arcgis.com/home/item.html?id=01f052c8995e4b9e889d73c3e210ebe3")!),
        MapAtURL(title: "Geology of United States",
                 image: #imageLiteral(resourceName: "OpenMapURLThumbnail3"),
                 url: URL(string:"https://www.arcgis.com/home/item.html?id=92ad152b9da94dee89b9e387dfe21acd")!)
    ]
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var blurView:UIVisualEffectView!
    @IBOutlet private weak var tableParentView:UIView!
    @IBOutlet private weak var tableView:UITableView!
    
    private var map:AGSMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultMapIndex = 0
        
        show(mapAtURL: mapModels[defaultMapIndex])
                
        //UI setup
        //add rounded corners for table's parent view
        tableParentView.layer.cornerRadius = 10
        
        //self sizing cells
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.selectRow(at: IndexPath(row: defaultMapIndex, section: 0), animated: false, scrollPosition: .none)
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OpenMapURLViewController"]
    }
    
    func show(mapAtURL:MapAtURL){
        map = AGSMap(url: mapAtURL.url)
        mapView.map = map
    }
    
    //MARK: - Actions
    
    @IBAction private func mapsAction() {
        //toggle table view
        blurView.isHidden = false
    }
    
    //MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapModels.count
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapAtURLCell", for: indexPath)
        cell.backgroundColor = .clear
        
        let mapModel = mapModels[indexPath.row]
        
        cell.textLabel?.text = mapModel.title
        cell.imageView?.image = mapModel.image
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        show(mapAtURL:mapModels[indexPath.row])

        //toggle table view
        blurView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
}
