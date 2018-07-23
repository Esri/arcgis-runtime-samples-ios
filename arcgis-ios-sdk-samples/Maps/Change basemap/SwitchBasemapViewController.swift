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

class SwitchBasemapViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var tableParentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    private var titles = ["Streets (Raster)", "Streets (Vector)", "Streets - Night (Vector)", "Imagery (Raster)", "Imagery with Labels (Raster)", "Imagery with Labels (Vector)", "Dark Gray Canvas (Vector)", "Light Gray Canvas (Raster)", "Light Gray Canvas (Vector)", "Navigation (Vector)", "OpenStreetMap (Raster)"]
    
    var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize the map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.streets())
        
        //assign the map to the map view
        self.mapView.map = map
                
        //UI setup
        //add rounded corners for table's parent view
        self.tableParentView.layer.cornerRadius = 10
        
        //self sizing cells
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SwitchBasemapViewController"]
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        self.blurView.isHidden = !self.blurView.isHidden
    }
    
    //MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basemapsCell", for: indexPath)
        cell.backgroundColor = .clear
        
        cell.textLabel?.text = self.titles[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.map.basemap = AGSBasemap.streets()
        case 1:
            self.map.basemap = AGSBasemap.streetsVector()
        case 2:
            self.map.basemap = AGSBasemap.streetsNightVector()
        case 3:
            self.map.basemap = AGSBasemap.imagery()
        case 4:
            self.map.basemap = AGSBasemap.imageryWithLabels()
        case 5:
            self.map.basemap = AGSBasemap.imageryWithLabelsVector()
        case 6:
            self.map.basemap = AGSBasemap.darkGrayCanvasVector()
        case 7:
            self.map.basemap = AGSBasemap.lightGrayCanvas()
        case 8:
            self.map.basemap = AGSBasemap.lightGrayCanvasVector()
        case 9:
            self.map.basemap = AGSBasemap.navigationVector()
        default:
            self.map.basemap = AGSBasemap.openStreetMap()
        }

        //toggle table view
        self.blurView.isHidden = !self.blurView.isHidden
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}
