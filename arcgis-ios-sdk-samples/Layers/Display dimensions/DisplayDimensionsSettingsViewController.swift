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

class DisplayDimensionsSettingsViewController: UITableViewController {
    // MARK: Storyboard views
    
    @IBOutlet var dimensionLayerVisibilitySwitch: UISwitch!
    @IBOutlet var definitionExpressionSwitch: UISwitch!
    
    // MARK: Properties
    
    /// The dimension layer passed from parent view controller.
    private let dimensionLayer: AGSDimensionLayer
    private var tableViewContentSizeObservation: NSKeyValueObservation?
    
    // MARK: Initializers
    
    init?(
        coder: NSCoder,
        dimensionLayer: AGSDimensionLayer
    ) {
        self.dimensionLayer = dimensionLayer
        super.init(coder: coder)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Actions
    
    @IBAction func toggleDimensionLayerVisibilityAction(_ sender: UISwitch) {
        dimensionLayer.isVisible.toggle()
        definitionExpressionSwitch.isEnabled = dimensionLayer.isVisible
    }
    
    @IBAction func toggleDefinitionExpressionAction(_ sender: UISwitch) {
        let expression = sender.isOn ? "DIMLENGTH >= 450" : ""
        dimensionLayer.definitionExpression = expression
    }
    
    // MARK: UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dimensionLayerVisibilitySwitch.isOn = dimensionLayer.isVisible
        definitionExpressionSwitch.isEnabled = dimensionLayer.isVisible
        definitionExpressionSwitch.isOn = !dimensionLayer.definitionExpression.isEmpty
        // Adjust the size of the table view according to its contents.
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] tableView, _ in
            preferredContentSize = CGSize(width: preferredContentSize.width, height: tableView.contentSize.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableViewContentSizeObservation = nil
    }
}
