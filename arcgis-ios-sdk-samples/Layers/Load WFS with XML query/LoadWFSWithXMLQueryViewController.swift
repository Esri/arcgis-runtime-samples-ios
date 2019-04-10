//
// Copyright © 2019 Esri.
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

/// A string containing the XML of the GetFeature request.
private let requestXML = """
    <wfs:GetFeature service="WFS" version="2.0.0"
    xmlns:Seattle_Downtown_Features="https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer"
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:fes="http://www.opengis.net/fes/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2">
    <wfs:Query typeNames="Seattle_Downtown_Features:Trees">
    <fes:Filter>
    <fes:PropertyIsLike wildCard="*" escapeChar="\">
    <fes:ValueReference>Trees:SCIENTIFIC</fes:ValueReference>
    <fes:Literal>Tilia *</fes:Literal>
    </fes:PropertyIsLike>
    </fes:Filter>
    </wfs:Query>
    </wfs:GetFeature>
    """

/// A view controller that manages the interface of the Load WFS with XML Query
/// sample.
class LoadWFSWithXMLQueryViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let featureTable = makeWFSFeatureTable()
            featureTable.populateFromService(withRequestXML: requestXML, clearCache: true) { [weak self, unowned featureTable] (_, _) in
                guard let extent = featureTable.extent else { return }
                self?.mapView.setViewpointGeometry(extent, padding: 50, completion: nil)
            }
            mapView.map = makeMap(featureTable: featureTable)
        }
    }
    
    /// Creates a WFS feature table.
    ///
    /// - Returns: A new `AGSWFSFeatureTable` object.
    func makeWFSFeatureTable() -> AGSWFSFeatureTable {
        let serviceURL = URL(string: "https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer?service=wfs&request=getcapabilities")!
        let tableName = "Seattle_Downtown_Features:Trees"
        let statesTable = AGSWFSFeatureTable(url: serviceURL, tableName: tableName)
        statesTable.axisOrder = .noSwap
        statesTable.featureRequestMode = .manualCache
        return statesTable
    }
    
    /// Creates a map with a feature layer from the given feature table.
    ///
    /// - Parameter featureTable: A feature table.
    /// - Returns: A new `AGSMap` object.
    func makeMap(featureTable: AGSFeatureTable) -> AGSMap {
        let map = AGSMap(basemap: .navigationVector())
        
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        map.operationalLayers.add(featureLayer)
        
        return map
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["LoadWFSWithXMLQueryViewController"]
    }
}
