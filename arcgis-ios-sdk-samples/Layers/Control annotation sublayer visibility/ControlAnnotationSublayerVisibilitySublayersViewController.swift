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

class ControlAnnotationSublayerVisibilitySublayersViewController: UITableViewController {
    var annotationSublayers = [AGSAnnotationSublayer]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    var mapScale = Double.nan {
        didSet {
            mapScaleDidChange(oldValue)
        }
    }
    
    /// The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    /// The observation of the table view's content size.
    private var tableViewContentSizeObservation: NSKeyValueObservation?
    
    func title(for annotationSublayer: AGSAnnotationSublayer) -> String {
        let maxScale = annotationSublayer.maxScale
        let minScale = annotationSublayer.minScale
        var title = annotationSublayer.name
        if !(maxScale.isNaN || minScale.isNaN) {
            let maxScaleString = scaleFormatter.string(from: maxScale as NSNumber)!
            let minScaleString = scaleFormatter.string(from: minScale as NSNumber)!
            title.append(String(format: " (1:%@ - 1:%@)", maxScaleString, minScaleString))
        }
        return title
    }
    
    func mapScaleDidChange(_ previousMapScale: Double) {
        var indexPaths = [IndexPath]()
        for row in annotationSublayers.indices {
            let annotationSublayer = annotationSublayers[row]
            let wasVisible = annotationSublayer.isVisible(atScale: previousMapScale)
            let isVisible = annotationSublayer.isVisible(atScale: mapScale)
            if isVisible != wasVisible {
                let indexPath = IndexPath(row: row, section: 0)
                indexPaths.append(indexPath)
            }
        }
        if !indexPaths.isEmpty {
            tableView.reloadRows(at: indexPaths, with: .automatic)
        }
    }
    
    // MARK: UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] (tableView, _) in
            self.preferredContentSize.height = tableView.contentSize.height
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableViewContentSizeObservation = nil
    }
}

extension ControlAnnotationSublayerVisibilitySublayersViewController: ControlAnnotationSublayerVisibilitySublayerCellDelegate {
    func sublayerCellDidToggleSwitch(_ sublayerCell: ControlAnnotationSublayerVisibilitySublayerCell) {
        guard let indexPath = tableView.indexPath(for: sublayerCell) else {
            return
        }
        
        annotationSublayers[indexPath.row].isVisible = sublayerCell.switch.isOn
    }
}

extension ControlAnnotationSublayerVisibilitySublayersViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return annotationSublayers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let annotationSublayer = annotationSublayers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SublayerCell", for: indexPath) as! ControlAnnotationSublayerVisibilitySublayerCell
        cell.textLabel?.text = title(for: annotationSublayer)
        cell.textLabel?.isEnabled = annotationSublayer.isVisible(atScale: mapScale)
        cell.switch.isOn = annotationSublayer.isVisible
        cell.delegate = self
        return cell
    }
}
