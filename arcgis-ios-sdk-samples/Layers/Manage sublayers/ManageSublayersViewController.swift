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

import UIKit
import ArcGIS

class ManageSublayersViewController: UIViewController, MapImageSublayersVCDelegate {

    @IBOutlet private var mapView:AGSMapView!
    
    private var workspaceID = "MyDatabaseWorkspaceIDSSR2"
    private var removedMapImageSublayers:[AGSArcGISMapImageSublayer]!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ManageSublayersViewController","MapImageSublayersVC"]
        
        //instantiate map with basemap
        let map = AGSMap(basemap: AGSBasemap.streets())
        
        //initialize map image layer
        self.mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer")!)
        
        //add layer to map
        map.operationalLayers.add(self.mapImageLayer)
        
        //initial viewpoint
        let envelope = AGSEnvelope(xMin: -13834661.666904, yMin: 331181.323482, xMax: -8255704.998713, yMax: 9118038.075882, spatialReference:AGSSpatialReference.webMercator())
        
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(targetExtent: envelope)
        
        //assign map to map view
        self.mapView.map = map
        
        //create sublayers from tableSublayerSource
        self.createSublayers()
    }
    
    private func createSublayers() {
        
        //We will create 2 mapImageSublayers from tableSublayerSource with known workspaceID and dataSourceName
        //These sublayers are not yet part of the mapImageLayer's sublayers, so will be shown as part of the 
        //removed sublayers array at first
        
        //array
        self.removedMapImageSublayers = [AGSArcGISMapImageSublayer]()
        
        //create tableSublayerSource from workspaceID and dataSourceName
        let tableSublayerSource1 = AGSTableSublayerSource(workspaceID: self.workspaceID, dataSourceName: "ss6.gdb.rivers")
        
        //create mapImageSublayer from tableSublayerSource
        let mapImageSublayer1 = AGSArcGISMapImageSublayer(id: 4, source: tableSublayerSource1)
        
        //assign a renderer to the sublayer
        let renderer1 = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid, color: .blue, width: 1))
        mapImageSublayer1.renderer = renderer1
        
        //name for the sublayer
        mapImageSublayer1.name = "Rivers"
        
        //create tableSublayerSource from workspaceID and dataSourceName
        let tableSublayerSource2 = AGSTableSublayerSource(workspaceID: self.workspaceID, dataSourceName: "ss6.gdb.lakes")
        
        //create mapImageSublayer from tableSublayerSource
        let mapImageSublayer2 = AGSArcGISMapImageSublayer(id: 5, source: tableSublayerSource2)
        
        //assign a renderer to the sublayer
        let renderer2 = AGSSimpleRenderer(symbol: AGSSimpleFillSymbol(style: .solid, color: .cyan, outline: nil))
        mapImageSublayer2.renderer = renderer2
        
        //name for the sublayer
        mapImageSublayer2.name = "Lakes"
        self.removedMapImageSublayers.append(contentsOf: [mapImageSublayer1, mapImageSublayer2])
        
    }
    
    //MARK: - MapImageSublayersVCDelegate
    
    func mapImageSublayersVC(mapImageSublayersVC: MapImageSublayersVC, didCloseWith removedMapImageSublayers: [AGSArcGISMapImageSublayer]) {
        
        self.removedMapImageSublayers = removedMapImageSublayers
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MapImageSublayersSegue" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.viewControllers[0] as! MapImageSublayersVC
            controller.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            controller.mapImageLayer = self.mapImageLayer
            controller.removedMapImageSublayers = self.removedMapImageSublayers
        }
    }
}
