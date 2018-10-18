//
// Copyright 2016 Esri.
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

protocol StretchRendererSettingsVCDelegate: AnyObject {
    
    func stretchRendererSettingsVC(_ stretchRendererSettingsVC: StretchRendererSettingsVC, didSelectStretchParameters parameters: AGSStretchParameters)
}

class StretchRendererSettingsVC: UITableViewController {
    
    weak var delegate: StretchRendererSettingsVCDelegate?
    
    @IBOutlet var stretchTypePicker: HorizontalPicker!
    
    enum StretchType: Int, CaseIterable {
        case minMax, percentClip, standardDeviation
        
        var label: String {
            switch self {
            case .minMax: return "MinMax"
            case .percentClip: return "PercentClip"
            case .standardDeviation: return "StdDeviation"
            }
        }
    }
    
    private var stretchType: StretchType = .minMax
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stretchTypePicker.delegate = self
        stretchTypePicker.options = StretchType.allCases.map({ (type) -> String in
            return type.label
        })
    }
    
    private func makeStretchParameters() -> AGSStretchParameters {
        switch stretchType {
        case .minMax:
            var minValue = 0, maxValue = 255
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                minValue = Int(cell.textField.text!) ?? 0
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? StretchRendererInputCell {
                maxValue = Int(cell.textField.text!) ?? 255
            }
            return AGSMinMaxStretchParameters(minValues: [minValue as NSNumber], maxValues: [maxValue as NSNumber])
        case .percentClip:
            var min = 0.0, max = 0.0
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                min = Double(cell.textField.text!) ?? 0
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? StretchRendererInputCell {
                max = Double(cell.textField.text!) ?? 0
            }
            return AGSPercentClipStretchParameters(min: min, max: max)
        case .standardDeviation:
            var factor = 1.0
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                factor = Double(cell.textField.text!) ?? 1
            }
            return AGSStandardDeviationStretchParameters(factor: factor)
        }
    }
    
    private func renderAction() {
        delegate?.stretchRendererSettingsVC(self, didSelectStretchParameters: makeStretchParameters())
    }
    
    //MARK: - Actions
    
    @IBAction func textFieldAction(_ sender: UITextField) {
        renderAction()
    }
    
    //MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch stretchType {
        case .minMax, .percentClip:
            return 3
        case .standardDeviation:
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Row0", for: indexPath)
            return cell
        }
        else {
            switch stretchType {
            case .minMax:
                return tableView.dequeueReusableCell(withIdentifier: "MinMaxRow\(indexPath.row)", for: indexPath)
            case .percentClip:
                return tableView.dequeueReusableCell(withIdentifier: "PercentClipRow\(indexPath.row)", for: indexPath)
            case .standardDeviation:
                return tableView.dequeueReusableCell(withIdentifier: "StandardDeviationRow1", for: indexPath)
            }
        }
    }
}

extension StretchRendererSettingsVC: HorizontalPickerDelegate {
    
    func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        stretchType = StretchType(rawValue: index)!
        tableView.reloadData()
        renderAction()
    }
    
}
