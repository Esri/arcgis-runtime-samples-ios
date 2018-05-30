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

class StatisticalQueryViewController: UIViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private var visualEffectView:UIVisualEffectView!
    @IBOutlet private var getStatisticsButton: UIButton!
    @IBOutlet private var onlyInCurrentExtentSwitch: UISwitch!
    @IBOutlet private var onlyBigCitiesSwitch: UISwitch!
    private var map: AGSMap?
    private var serviceFeatureTable: AGSServiceFeatureTable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StatisticalQueryViewController"]
        
        // Constraint visual effect view to the map view's attribution label
        visualEffectView.bottomAnchor.constraint(equalTo: mapView.attributionTopAnchor, constant:-10.0).isActive = true
        
        // Corner radius for button
        getStatisticsButton.layer.cornerRadius = 10
        
        // Initialize map and set it on map view
        map = AGSMap(basemap: AGSBasemap.streetsVector())
        mapView.map = map

        // Initialize feature table, layer and add it to map
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: serviceFeatureTable!)
        map?.operationalLayers.add(featureLayer)
    }
    
    // MARK: Actions
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        //
        // Add the statistic definitions
        var statisticDefinitions = [AGSStatisticDefinition]()
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .average, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .minimum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .maximum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .sum, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .standardDeviation, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .variance, outputAlias: nil))
        statisticDefinitions.append(AGSStatisticDefinition(onFieldName: "POP", statisticType: .count, outputAlias: nil))
        
        // Create the parameters with statistic definitions
        let statisticsQueryParameters = AGSStatisticsQueryParameters(statisticDefinitions: statisticDefinitions)
        
        // If only using features in the current extent, set up the spatial filter for the statistics query parameters
        if (onlyInCurrentExtentSwitch.isOn) {
            //
            // Set the statistics query parameters geometry with the envelope
            statisticsQueryParameters.geometry = mapView.visibleArea?.extent
            
            // Set the spatial relationship to Intersects (which is the default)
            statisticsQueryParameters.spatialRelationship = .intersects
        }
        
        // If only evaluating the largest cities (over 5 million in population), set up an attribute filter
        if (onlyBigCitiesSwitch.isOn) {
            statisticsQueryParameters.whereClause = "POP_RANK = 1"
        }
        
        // Execute the statistical query with parameters
        serviceFeatureTable?.queryStatistics(with: statisticsQueryParameters, completion: { [weak self] (statisticsQueryResult, error) in
            //
            // If there an error, display it
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            // Get the result
            if let statisticRecordEnumerator = statisticsQueryResult?.statisticRecordEnumerator() {
                //
                // Let's build result message
                var resultMessage = " \n"
                while statisticRecordEnumerator.hasNextObject() {
                    let statisticRecord = statisticRecordEnumerator.nextObject()
                    for (key, value) in (statisticRecord?.statistics)!  {
                        resultMessage += "\(key): \(value) \n"
                    }
                }
                
                // Show result
                self?.showResult(message: resultMessage)
            }
        })
    }
    
    // MARK: Helper Methods
    
    private func showResult(message: String) {
        let alertController = UIAlertController(title: "Statistical Query Results", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

