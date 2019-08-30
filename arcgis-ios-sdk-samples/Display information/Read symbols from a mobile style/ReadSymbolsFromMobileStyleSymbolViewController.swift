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

/// A view controller that manages the composition of the multilayer symbol for
/// the Read Symbols from a Mobile Style sample.
class ReadSymbolsFromMobileStyleSymbolViewController: UIViewController {
    /// The image view for displaying a preview of the symbol.
    @IBOutlet var previewImageView: UIImageView!
    
    /// The search results from the symbol style.
    var symbolStyleSearchResults = [AGSSymbolStyleSearchResult]() {
        didSet {
            loadViewIfNeeded()
            let searchResultsByCategory = Dictionary(grouping: symbolStyleSearchResults) { $0.category }
            settingsViewController.eyes = searchResultsByCategory["Eyes"] ?? []
            settingsViewController.mouths = searchResultsByCategory["Mouth"] ?? []
            settingsViewController.hats = searchResultsByCategory["Hat"] ?? []
            updateSymbol()
        }
    }
    /// The symbol settings view controller.
    var settingsViewController: ReadSymbolsFromMobileStyleSymbolSettingsViewController!
    
    /// The current operation, either creating a symbol or creating a swatch.
    var currentOperation: AGSCancelable?
    
    /// Updates the symbol based on the current settings.
    func updateSymbol() {
        currentOperation?.cancel()
        let keys = [
            "Face1",
            settingsViewController.selectedEyes?.key,
            settingsViewController.selectedMouth?.key,
            settingsViewController.selectedHat?.key
        ].compactMap { $0 }
        currentOperation = symbolStyle.symbol(forKeys: keys) { [weak self] (symbol, error) in
            guard let self = self else { return }
            if let symbol = symbol as? AGSMultilayerPointSymbol {
                let layers = symbol.symbolLayers as! [AGSSymbolLayer]
                // Color lock all but the first layer.
                layers.enumerated().forEach { $1.isColorLocked = $0 != 0 }
                symbol.color = self.settingsViewController.selectedColor
                symbol.size = CGFloat(self.settingsViewController.selectedSize)
                self.symbol = symbol
            } else if let error = error {
                print("Error getting symbol: \(error)")
            }
        }
    }
    
    /// Updates the preview based on the current symbol.
    func updatePreview() {
        currentOperation?.cancel()
        let size = settingsViewController.selectedSize
        currentOperation = symbol?.createSwatch(withWidth: size, height: size, screen: .main, backgroundColor: nil) { [weak self] (image, error) in
            guard let self = self else { return }
            self.currentOperation = nil
            if let image = image {
                self.previewImageView.image = image
            } else if let error = error {
                print("Error cerating swatch: \(error)")
            }
        }
    }
    
    /// Called in response to the Done button being tapped.
    @IBAction func done() {
        dismiss(animated: true)
    }
    
    /// The symbol style used by the view controller.
    let symbolStyle = AGSSymbolStyle(name: "emoji-mobile")
    /// The symbol managed by the view controller.
    private(set) var symbol: AGSSymbol? {
        didSet {
            updatePreview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        symbolStyle.load { [weak self] error in
            guard error == nil else { return }
            self?.symbolStyle.defaultSearchParameters { (searchParameters, _) in
                guard let searchParameters = searchParameters else { return }
                self?.symbolStyle.searchSymbols(with: searchParameters) { (searchResults, _) in
                    guard let searchResults = searchResults else { return }
                    self?.symbolStyleSearchResults = searchResults
                }
            }
        }
    }
    
    // MARK: UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsViewController = segue.destination as? ReadSymbolsFromMobileStyleSymbolSettingsViewController {
            settingsViewController.delegate = self
            self.settingsViewController = settingsViewController
        }
    }
}

extension ReadSymbolsFromMobileStyleSymbolViewController: ReadSymbolsFromMobileStyleSymbolSettingsViewControllerDelegate {
    func symbolSettingsViewControllerSettingsDidChange(_ controller: ReadSymbolsFromMobileStyleSymbolSettingsViewController) {
        updateSymbol()
    }
}
