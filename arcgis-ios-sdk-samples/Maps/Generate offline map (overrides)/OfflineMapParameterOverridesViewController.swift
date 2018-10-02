//
// Copyright 2018 Esri.
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

class OfflineMapParameterOverridesViewController: UITableViewController {
    
    var parameterOverrides: AGSGenerateOfflineMapParameterOverrides?
    var map: AGSMap?
    
    //MARK: - Outlets

    /// The min scale level for the output. Note that lower values are zoomed further out,
    /// i.e. 0 has the least detail, but one tile covers the entire Earth.
    @IBOutlet weak var minScaleLevelSlider: UISlider!
    
    /// The max scale level for the output. Note that higher values are zoomed further in,
    /// i.e. 23 has the most detail, but each tile covers a tiny area.
    @IBOutlet weak var maxScaleLevelSlider: UISlider!
    
    /// The extra padding added to the extent rect to fetch a larger area, in meters.
    @IBOutlet weak var basemapExtentBufferSlider: UISlider!
    
    /// Switch indicating if the system valves layer should be included in the download.
    @IBOutlet weak var includeSystemValvesSwitch: UISwitch!
    ///Switch indicating if the service connections layer should be included in the download.
    @IBOutlet weak var includeServiceConnectionsSwitch: UISwitch!
    
    /// The minimum flow rate by which to filter features in the Hydrants layer, in gallons per minute.
    @IBOutlet weak var minHydrantFlowRateSlider: UISlider!
    
    ///Switch indicating if the pipe layers should be restricted to the extent frame.
    @IBOutlet weak var cropWaterPipesToExtentSwitch: UISwitch!
    
    @IBOutlet weak var minScaleLevelLabel: UILabel!
    @IBOutlet weak var maxScaleLevelLabel: UILabel!
    @IBOutlet weak var extentBufferLabel: UILabel!
    @IBOutlet weak var minHydrantFlowRateLabel: UILabel!
    
    //MARK: - Actions
    
    @IBAction func sliderChangeAction(_ sender: UISlider) {
        if sender == minScaleLevelSlider {
            // Disallow a min value greater than the maximum
            if sender.value > maxScaleLevelSlider.value {
                sender.value = maxScaleLevelSlider.value
            }
        }
        else if sender == maxScaleLevelSlider {
            // Disallow a max value less than the minimum
            if sender.value < minScaleLevelSlider.value {
                sender.value = minScaleLevelSlider.value
            }
        }
        // Update this slider's text field to display the new value
        updateTextField(for: sender)
    }
    
    //MARK: - Text field updating
    
    private let numberFormatter = NumberFormatter()
    
    private func updateTextField(for slider: UISlider){
        if let text = numberFormatter.string(from: slider.value as NSNumber) {
            if slider == minScaleLevelSlider {
                minScaleLevelLabel.text = text
            }
            else if slider == maxScaleLevelSlider {
                maxScaleLevelLabel.text = text
            }
            else if slider == basemapExtentBufferSlider {
                extentBufferLabel.text = text
            }
            else if slider == minHydrantFlowRateSlider {
                minHydrantFlowRateLabel.text = text
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update each text field to display its slider's default value
        for slider in [minScaleLevelSlider,
                       maxScaleLevelSlider,
                       basemapExtentBufferSlider,
                       minHydrantFlowRateSlider] {
            updateTextField(for: slider!)
        }
    }
    
    //MARK: - Cancelling
    
    /// The completion handler to run if the user clicks cancel
    var cancelHandler: ((OfflineMapParameterOverridesViewController) -> Void)?
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        // Run the handler
        cancelHandler?(self)
    }
    
    //MARK: - Completion
    
    /// The completion handler to run once the user is done setting the parameters.
    var startJobHandler: ((OfflineMapParameterOverridesViewController) -> Void)?
    
    @IBAction func startAction(_ sender: UIBarButtonItem) {
        // Update the parameters based on the user's input
        setParameterOverridesFromUI()
        // Run the handler callback now that the parameters have been updated
        startJobHandler?(self)
    }
    
    /// Updates the `AGSGenerateOfflineMapParameterOverrides` object with the user-set values.
    private func setParameterOverridesFromUI(){
        
        restrictBasemapScaleLevelRange()
        bufferBasemapAreaOfInterest()
        evaluateLayerVisiblity()
        addHydrantFilter()
        evaluatePipeLayersExtentCropping()
    }
    
    //MARK: - Basemap adjustment
    
    private func restrictBasemapScaleLevelRange() {
        
        /// The user-set min scale value
        let minScale = Int(minScaleLevelSlider.value)
        /// The user-set max scale value
        let maxScale = Int(maxScaleLevelSlider.value)
        
        guard let tileCacheParameters = getExportTileCacheParametersForBasemapLayer(),
            // Ensure that the lower bound of the range is not greater than the upper bound
            minScale <= maxScale else {
                return
        }
        
        let scaleLevelRange = minScale...maxScale
        let scaleLevelIDs = Array(scaleLevelRange) as [NSNumber]
        // Override the default level IDs
        tileCacheParameters.levelIDs = scaleLevelIDs
    }
    
    private func bufferBasemapAreaOfInterest() {
        
        guard let tileCacheParameters = getExportTileCacheParametersForBasemapLayer(),
            /// The area initially specified for download when the default parameters object was created
            let areaOfInterest = tileCacheParameters.areaOfInterest else{
                return
        }
        
        /// The user-set distance value
        let basemapExtentBufferDistance = Double(basemapExtentBufferSlider.value)
        
        // Assuming the distance is positive, expand the downloaded area by the given amount
        let bufferedArea = AGSGeometryEngine.bufferGeometry(areaOfInterest, byDistance: basemapExtentBufferDistance)
        // Override the default area of interest
        tileCacheParameters.areaOfInterest = bufferedArea
    }
    
    //MARK: - Layer adjustment
    
    private func addHydrantFilter(){
        
        /// The user-set min flow rate value
        let minFlowRate = minHydrantFlowRateSlider.value
        
        for option in getGenerateGeodatabaseParametersLayerOptions(forLayerNamed: "Hydrant") {
            // Set the SQL where clause for this layer's options, filtering features based on the FLOW field values
            option.whereClause = "FLOW >= \(minFlowRate)"
        }
    }
    
    private func evaluateLayerVisiblity(){
        
        func excludeLayerFromDownload(named name: String) {
            if let layer = operationalMapLayer(named: name),
                let serviceLayerID = serviceLayerID(for: layer),
                let parameters = getGenerateGeodatabaseParameters(forLayer: layer){
                // Remove the options for this layer from the parameters
                parameters.layerOptions.removeAll { $0.layerID == serviceLayerID }
            }
        }
        
        // If the switch is off
        if !includeSystemValvesSwitch.isOn {
            excludeLayerFromDownload(named: "System Valve")
        }
        if !includeServiceConnectionsSwitch.isOn {
            excludeLayerFromDownload(named: "Service Connection")
        }
        
    }
    
    private func evaluatePipeLayersExtentCropping(){
        // If the switch is off
        if !cropWaterPipesToExtentSwitch.isOn {
            // Two layers contain pipes, so loop through both
            for pipeLayerName in ["Main", "Lateral"]{
                for option in getGenerateGeodatabaseParametersLayerOptions(forLayerNamed: pipeLayerName) {
                    // Turn off the geometry extent evaluation so that the entire layer is downloaded
                    option.useGeometry = false
                }
            }
        }
    }
    
    //MARK: - Basemap helpers
    
    /// Retrieves the basemap's parameters from the `exportTileCacheParameters` dictionary.
    private func getExportTileCacheParametersForBasemapLayer() -> AGSExportTileCacheParameters? {
        if let basemapLayer = map?.basemap.baseLayers.firstObject as? AGSLayer{
            let key = AGSOfflineMapParametersKey(layer: basemapLayer)
            return parameterOverrides?.exportTileCacheParameters[key]
        }
        return nil
    }
    
    //MARK: - Layer helpers
    
    /// Retrieves the operational layer in the map with the given name, if it exists.
    private func operationalMapLayer(named name: String) -> AGSLayer? {
        let layers = map?.operationalLayers as? [AGSLayer]
        return layers?.first(where: { $0.name == name })
    }
    
    /// The service ID retrived from the layer's `AGSArcGISFeatureLayerInfo`, if it is a feature layer.
    /// Needed for use in conjunction with the `layerID` of `AGSGenerateLayerOption`.
    /// This is not the same as the `layerID` property of `AGSLayer`.
    private func serviceLayerID(for layer: AGSLayer) -> Int? {
        if let featureLayer = layer as? AGSFeatureLayer,
            let featureTable = featureLayer.featureTable as? AGSArcGISFeatureTable,
            let featureLayerInfo = featureTable.layerInfo {
            return featureLayerInfo.serviceLayerID
        }
        return nil
    }
    
    //MARK: - AGSGenerateGeodatabaseParameters helpers
    
    /// Retrieves this layer's parameters from the `generateGeodatabaseParameters` dictionary.
    private func getGenerateGeodatabaseParameters(forLayer layer: AGSLayer) -> AGSGenerateGeodatabaseParameters? {
        /// The parameters key for this layer
        let key = AGSOfflineMapParametersKey(layer: layer)
        return parameterOverrides?.generateGeodatabaseParameters[key]
    }
    /// Retrieves the layer's options from the layer's parameter in the `generateGeodatabaseParameters` dictionary.
    private func getGenerateGeodatabaseParametersLayerOptions(forLayerNamed name: String) -> [AGSGenerateLayerOption]{
        if let layer = operationalMapLayer(named: name),
            let serviceLayerID = serviceLayerID(for: layer),
            let parameters = getGenerateGeodatabaseParameters(forLayer: layer){
            // The layers options may correspond to multiple layers, so filter based on the ID of the target layer.
            return parameters.layerOptions.filter { (option) -> Bool in
                return option.layerID == serviceLayerID
            }
        }
        return []
    }
}
