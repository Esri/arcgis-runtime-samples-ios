// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class CreateSymbolStylesFromWebStylesViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap(featureLayer: featureLayer)
            mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 34.28301,
                    longitude: -118.44186,
                    scale: 1e4
                )
            )
        }
    }
    /// The button to show legend table.
    @IBOutlet var legendBarButtonItem: UIBarButtonItem!
    
    // MARK: Instance properties
    
    /// The Esri 2D point symbol style created from a web style.
    let symbolStyle = AGSSymbolStyle(styleName: "Esri2DPointSymbolsStyle", portal: .arcGISOnline(withLoginRequired: false))
    /// The observation on the map view's `mapScale` property.
    var mapScaleObservation: NSKeyValueObservation?
    /// A cache for the image swatches of the symbols.
    var cachedImages = [AGSSymbol: UIImage]()
    /// The data source for the legend table.
    private var symbolsDataSource: SymbolsDataSource?
    /// A list of symbols created from the web style.
    private var symbols = [(category: SymbolCategory, symbol: AGSSymbol)]()
    
    /// A feature layer with LA County Points of Interest service.
    let featureLayer: AGSFeatureLayer = {
        let serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "http://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/LA_County_Points_of_Interest/FeatureServer/0")!)
        let layer = AGSFeatureLayer(featureTable: serviceFeatureTable)
        return layer
    }()
    
    // MARK: Methods
    
    /// Create a map with an `AGSFeatureLayer` added to its operational layers.
    /// - Parameter featureLayer: An `AGSFeatureLayer` object.
    /// - Returns: An `AGSMap` object.
    func makeMap(featureLayer: AGSFeatureLayer) -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISLightGray)
        map.referenceScale = 1e5
        map.operationalLayers.add(featureLayer)
        return map
    }
    
    /// Create an `AGSUniqueValueRenderer` to render feature layer with symbol styles.
    /// - Parameter fieldNames: The attributes to match the unique values against.
    /// - Returns: An `AGSUniqueValueRenderer` object.
    func makeUniqueValueRenderer(fieldNames: [String]) -> AGSUniqueValueRenderer {
        let renderer = AGSUniqueValueRenderer()
        renderer.fieldNames = fieldNames
        renderer.uniqueValues = symbols.flatMap { category, symbol in
            // For each category value of a symbol, we need to create a
            // unique value for it, so the field name matches to all categories.
            category.symbolCategoryValues.map { symbolValue in
                AGSUniqueValue(description: "", label: category.symbolName, symbol: symbol, values: [symbolValue])
            }
        }
        return renderer
    }
    
    /// Get certain categories of symbols from a symbol style.
    /// - Parameters:
    ///   - symbolStyle: An `AGSSymbolStyle` object.
    ///   - categories: The types of symbols to search in the symbol style.
    ///   - completion: A closure executed upon success.
    private func getSymbols(symbolStyle: AGSSymbolStyle, categories: [SymbolCategory], completion: @escaping () -> Void) {
        let getSymbolsGroup = DispatchGroup()
        var symbols = [(SymbolCategory, AGSSymbol)]()
        
        categories.forEach { category in
            getSymbolsGroup.enter()
            symbolStyle.symbol(forKeys: [category.symbolName]) { symbol, _ in
                defer {
                    getSymbolsGroup.leave()
                }
                // Add the symbol to the result collection and ignore any error.
                if let symbol = symbol {
                    symbols.append((category, symbol))
                }
            }
        }
        getSymbolsGroup.notify(queue: .main) { [weak self] in
            self?.symbols = symbols.sorted { $0.0 < $1.0 }
            completion()
        }
    }
    
    /// Asynchronously create image swatches for the symbols.
    func createImages(completion: @escaping () -> Void) {
        let createImagesGroup = DispatchGroup()
        var cachedImages = [AGSSymbol: UIImage]()
        
        symbols.forEach { _, symbol in
            createImagesGroup.enter()
            symbol.createSwatch { image, _ in
                defer {
                    createImagesGroup.leave()
                }
                if let image = image {
                    cachedImages[symbol] = image
                }
            }
        }
        createImagesGroup.notify(queue: .main) { [weak self] in
            self?.cachedImages = cachedImages
            completion()
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CreateSymbolStylesFromWebStylesViewController"]
        
        // Get the symbols from the symbol style hosted on an ArcGIS portal.
        getSymbols(symbolStyle: symbolStyle, categories: SymbolCategory.allCases) { [weak self] in
            self?.featureLayer.renderer = self?.makeUniqueValueRenderer(fieldNames: ["cat2"])
            self?.createImages {
                self?.legendBarButtonItem.isEnabled = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapScaleObservation = mapView.observe(\.mapScale, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.featureLayer.scaleSymbols = self.mapView.mapScale >= 8e4
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapScaleObservation = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LegendTableSegue",
           let controller = segue.destination as? UITableViewController {
            controller.presentationController?.delegate = self
            // The data source for the legend table.
            let legendItems = symbols.map { LegendItem(name: $0.symbolName, image: cachedImages[$1]!) }
            symbolsDataSource = SymbolsDataSource(legendItems: legendItems)
            controller.tableView.dataSource = symbolsDataSource
        }
    }
    
    @IBAction func unwindAction(unwindSegue: UIStoryboardSegue) {
        // Release the data source when the table view controller is dismissed.
        symbolsDataSource = nil
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Ensure that the settings are shown in a popover on small displays.
        return .none
    }
}

// MARK: - SymbolsDataSource, UITableViewDataSource

private class SymbolsDataSource: NSObject, UITableViewDataSource {
    /// The legend items for the legend table.
    private let legendItems: [LegendItem]
    
    init(legendItems: [LegendItem]) {
        self.legendItems = legendItems
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        legendItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let legendItem = legendItems[indexPath.row]
        cell.textLabel?.text = legendItem.name
        cell.imageView?.image = legendItem.image
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Symbol Styles"
    }
}

// MARK: - LegendItem

private struct LegendItem {
    var name: String
    var image: UIImage
}

// MARK: - SymbolCategory

private enum SymbolCategory: CaseIterable, Comparable {
    case atm, beach, campground, cityHall, hospital, library, park, placeOfWorship, policeStation, postOffice, school, trail
    
    /// The names of the symbols in the web style.
    var symbolName: String {
        let name: String
        switch self {
        case .atm:
            name = "atm"
        case .beach:
            name = "beach"
        case .campground:
            name = "campground"
        case .cityHall:
            name = "city-hall"
        case .hospital:
            name = "hospital"
        case .library:
            name = "library"
        case .park:
            name = "park"
        case .placeOfWorship:
            name = "place-of-worship"
        case .policeStation:
            name = "police-station"
        case .postOffice:
            name = "post-office"
        case .school:
            name = "school"
        case .trail:
            name = "trail"
        }
        return name
    }
    
    /// The category names of features represented by a type of symbol.
    var symbolCategoryValues: [String] {
        let values: [String]
        switch self {
        case .atm:
            values = ["Banking and Finance"]
        case .beach:
            values = ["Beaches and Marinas"]
        case .campground:
            values = ["Campgrounds"]
        case .cityHall:
            values = ["City Halls", "Government Offices"]
        case .hospital:
            values = ["Hospitals and Medical Centers", "Health Screening and Testing", "Health Centers", "Mental Health Centers"]
        case .library:
            values = ["Libraries"]
        case .park:
            values = ["Parks and Gardens"]
        case .placeOfWorship:
            values = ["Churches"]
        case .policeStation:
            values = ["Sheriff and Police Stations"]
        case .postOffice:
            values = ["DHL Locations", "Federal Express Locations"]
        case .school:
            values = ["Public High Schools", "Public Elementary Schools", "Private and Charter Schools"]
        case .trail:
            values = ["Trails"]
        }
        return values
    }
}
