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

// wrapper classes used to pass the model objects around by reference
private class DoubleObject {
    var double: Double
    init(_ double: Double){
        self.double = double
    }
}
private class BoolObject {
    var bool: Bool
    init(_ bool: Bool){
        self.bool = bool
    }
}

class OfflineMapParameterOverridesViewController: UITableViewController {
    
    // private var localParameters = LocalParameters()
    var parameterOverrides: AGSGenerateOfflineMapParameterOverrides?
    var map: AGSMap?
    
    //MARK: - model values

    /// The min scale level for the output. Note that lower values are zoomed further out,
    /// i.e. 0 has the least detail, but one tile covers the entire Earth.
    private var basemapMinScaleLevel = DoubleObject(0)
    
    /// The max scale level for the output. Note that higher values are zoomed further in,
    /// i.e. 23 has the most detail, but each tile covers a tiny area.
    private var basemapMaxScaleLevel = DoubleObject(23)
    
    /// The extra padding added to the extent rect to fetch a larger area, in meters.
    private var basemapExtentBuffer = DoubleObject(0)
    
    /// A flag indicating if the system valves layer should be included in the download.
    private var includeSystemValves = BoolObject(true)
    /// A flag indicating if the service connections layer should be included in the download.
    private var includeServiceConnections = BoolObject(true)
    
    /// The minimum flow rate by which to filter features in the Hydrants layer, in gallons per minute.
    private var minHydrantFlowRate = DoubleObject(0)
    
    /// A flag indicating if the pipe layers should be restricted to the extent frame.
    private var cropWaterPipesToExtent = BoolObject(true)
    
    //MARK: - table model
    
    /// An enum to organize the table view sections.
    private enum Section: Int, CaseIterable {
        case basemap, includeLayers, filterFeature, cropLayer
        
        var numberOfRows: Int{
            switch self {
            case .basemap: return 3
            case .includeLayers: return 2
            case .filterFeature: return 1
            case .cropLayer: return 1
            }
        }
        
        var label: String{
            switch self {
            case .basemap: return "Adjust The Basemap"
            case .includeLayers: return "Include Layers"
            case .filterFeature: return "Filter Feature Layer"
            case .cropLayer: return "Crop Layer To Extent"
            }
        }
    }
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section(rawValue: section)!.numberOfRows
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)!.label
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // load the cell based on the section and row
        switch Section(rawValue: indexPath.section)! {
        case .basemap:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineMapParamaterSliderCell") as! OfflineMapParamaterSliderCell
            switch indexPath.row{
            case 0:
                cell.label?.text = "Min Scale Level"
                cell.setRange(min: 0, max: 23)
                cell.doubleObject = basemapMinScaleLevel
                 // do not allow a min greater than the max
                cell.maxConstraint = basemapMaxScaleLevel
            case 1:
                cell.label?.text = "Max Scale Level"
                cell.setRange(min: 0, max: 23)
                cell.doubleObject = basemapMaxScaleLevel
                // do not allow a max less than the min
                cell.minConstraint = basemapMinScaleLevel
            default:
                cell.label?.text = "Extent Buffer Distance"
                cell.setRange(min: 0, max: 500)
                cell.doubleObject = basemapExtentBuffer
            }
            return cell
        case .includeLayers:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineMapParamaterSwitchCell") as! OfflineMapParamaterSwitchCell
            switch indexPath.row{
            case 0:
                cell.label?.text = "System Valves"
                cell.boolObject = includeSystemValves
            default:
                cell.label?.text = "Service Connections"
                cell.boolObject = includeServiceConnections
            }
            return cell
        case .filterFeature:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineMapParamaterSliderCell") as! OfflineMapParamaterSliderCell
            cell.label.text = "Min Hydrant Flow Rate"
            cell.setRange(min: 0, max: 1500)
            cell.doubleObject = minHydrantFlowRate
            return cell
        case .cropLayer:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineMapParamaterSwitchCell") as! OfflineMapParamaterSwitchCell
            cell.label.text = "Water Pipes"
            cell.boolObject = cropWaterPipesToExtent
            return cell
        }
    }
    
    //MARK: - UITabelViewDelegate
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // disallow cell highlighting and therefore selection
        return false
    }
    
    //MARK: - cancelling
    
    /// The completion handler to run if the user clicks cancel
    var cancelHandler: ((OfflineMapParameterOverridesViewController)->())?
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        // Run the handler
        cancelHandler?(self)
        // close the view
        navigationController?.dismiss(animated: true)
    }
    
    //MARK: - completion
    
    /// The completion handler to run once the user is done setting the parameters.
    var startJobHandler: ((OfflineMapParameterOverridesViewController)->())?
    
    @IBAction func startAction(_ sender: UIBarButtonItem) {
        // Update the parameters based on the user's input
        setParameterOverridesFromUI()
        // Run the handler callback now that the parameters have been updated
        startJobHandler?(self)
        // close the view
        navigationController?.dismiss(animated: true)
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
        let minScale = Int(basemapMinScaleLevel.double)
        /// The user-set max scale value
        let maxScale = Int(basemapMaxScaleLevel.double)
        
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
        let basemapExtentBufferDistance = basemapExtentBuffer.double
        
        // Assuming the distance is positive, expand the downloaded area by the given amount
        let bufferedArea = AGSGeometryEngine.bufferGeometry(areaOfInterest, byDistance: basemapExtentBufferDistance)
        // Override the default area of interest
        tileCacheParameters.areaOfInterest = bufferedArea
    }
    
    //MARK: - Layer adjustment
    
    private func addHydrantFilter(){
        
        /// The user-set min flow rate value
        let minFlowRate = minHydrantFlowRate.double
        
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
                parameters.layerOptions.removeAll { return $0.layerID == serviceLayerID }
            }
        }
        
        // If the switch is off
        if !includeSystemValves.bool {
            excludeLayerFromDownload(named: "System Valve")
        }
        if !includeServiceConnections.bool {
            excludeLayerFromDownload(named: "Service Connection")
        }
        
    }
    
    private func evaluatePipeLayersExtentCropping(){
        // If the switch is off
        if !cropWaterPipesToExtent.bool {
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

// UITableViewCell subclasses

class OfflineMapParamaterSliderCell: UITableViewCell{
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!
    
    private var numberFormatter = NumberFormatter()
    
    fileprivate var doubleObject: DoubleObject!{
        didSet{
            updateUIForObject()
        }
    }
    
    // other double values that constrain this cell's double
    fileprivate var minConstraint: DoubleObject?
    fileprivate var maxConstraint: DoubleObject?
    
    private func validateAndSetDouble(_ double: Double){
        var double = double
        if let minConstraint = minConstraint,
            double < minConstraint.double {
            double = minConstraint.double
        }
        if let maxConstraint = maxConstraint,
            double > maxConstraint.double {
            double = maxConstraint.double
        }
        doubleObject.double = double
    }
    
    func updateUIForObject(){
        if let double = doubleObject?.double{
            slider.value = Float(double)
            textField.text = numberFormatter.string(from: double as NSNumber)
        }
    }
    
    func setRange(min:Double,max:Double){
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        numberFormatter.minimum = min as NSNumber
        numberFormatter.maximum = max as NSNumber
    }
    
    @IBAction func sliderAction(_ sender: UISlider) {
        validateAndSetDouble(Double(sender.value))
        updateUIForObject()
    }
    
    @IBAction func valueFieldAction(_ sender: UITextField) {
        if let string = sender.text,
            let number = numberFormatter.number(from: string) {
            validateAndSetDouble(number.doubleValue)
        }
        updateUIForObject()
    }
}

class OfflineMapParamaterSwitchCell: UITableViewCell{
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    
    fileprivate var boolObject: BoolObject!{
        didSet{
            self.switch.isOn = boolObject.bool
        }
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        boolObject.bool = sender.isOn
    }
}
