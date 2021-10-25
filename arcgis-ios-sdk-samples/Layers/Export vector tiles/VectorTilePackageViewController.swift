// Copyright 2021 Esri.
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

protocol VectorTilePackageViewControllerDelegate: AnyObject {
    func optionsViewController(_ controller: ConfigureSubnetworkTraceOptionsViewController, didCreate: AGSUtilityTraceConditionalExpression)
}

class VectorTilePackageViewController: UIViewController {
    @IBOutlet var resultView: AGSMapView!
    var tiledLayerResult: AGSArcGISVectorTiledLayer?
    var extent: AGSEnvelope?
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let tiledLayerResult = tiledLayerResult,
            let extent = extent
        else { return }
        resultView.map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayerResult))
        resultView.setViewpoint(AGSViewpoint(targetExtent: extent))
    }
}
