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

protocol RGBRendererSettingsVCDelegate: AnyObject {
    func rgbRendererSettingsVC(_ rgbRendererSettingsVC: RGBRendererSettingsVC, didSelectStretchParameters parameters: AGSStretchParameters)
}

class RGBRendererSettingsVC: UITableViewController {
    weak var delegate: RGBRendererSettingsVCDelegate?
    
    weak var stretchTypeCell: UITableViewCell?
    
    private enum StretchType: Int, CaseIterable {
        case minMax, percentClip, standardDeviation
        
        var label: String {
            switch self {
            case .minMax: return "MinMax"
            case .percentClip: return "PercentClip"
            case .standardDeviation: return "StdDeviation"
            }
        }
    }
    
    func setupForParameters(_ parameters: AGSStretchParameters) {
        switch parameters {
        case let parameters as AGSMinMaxStretchParameters:
            minValues = parameters.minValues as! [Double]
            maxValues = parameters.maxValues as! [Double]
            stretchType = .minMax
        case let parameters as AGSPercentClipStretchParameters:
            stretchType = .percentClip
            percentClipMin = parameters.min
            percentClipMax = parameters.max
        case let parameters as AGSStandardDeviationStretchParameters:
            stretchType = .standardDeviation
            standardDeviationFactor = parameters.factor
        default:
            break
        }
    }
    
    private var minValues: [Double] = [0, 0, 0]
    private var maxValues: [Double] = [255, 255, 255]
    private var percentClipMin: Double = 0
    private var percentClipMax: Double = 1
    private var standardDeviationFactor: Double = 1
    
    private var stretchType: RGBRendererSettingsVC.StretchType = .minMax {
        didSet {
            updateStretchTypeLabel()
        }
    }
    
    private func updateStretchTypeLabel() {
        stretchTypeCell?.detailTextLabel?.text = stretchType.label
    }
    
    private func makeStretchParameters() -> AGSStretchParameters {
        //get the values from textFields in rows based on the selected stretch type
        switch stretchType {
        case .minMax:
            var minValue1 = 0, minValue2 = 0, minValue3 = 0, maxValue1 = 255, maxValue2 = 255, maxValue3 = 255
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRenderer3InputCell {
                minValue1 = Int(cell.textField1.text!) ?? 0
                minValue2 = Int(cell.textField2.text!) ?? 0
                minValue3 = Int(cell.textField3.text!) ?? 0
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? RGBRenderer3InputCell {
                maxValue1 = Int(cell.textField1.text!) ?? 255
                maxValue2 = Int(cell.textField2.text!) ?? 255
                maxValue3 = Int(cell.textField3.text!) ?? 255
            }
            return AGSMinMaxStretchParameters(
                minValues: [minValue1, minValue2, minValue3] as [NSNumber],
                maxValues: [maxValue1, maxValue2, maxValue3] as [NSNumber]
            )
        case .percentClip:
            var min = 0.0, max = 0.0
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRendererInputCell {
                min = Double(cell.textField.text!) ?? 0
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? RGBRendererInputCell {
                max = Double(cell.textField.text!) ?? 0
            }
            return AGSPercentClipStretchParameters(min: min, max: max)
        case .standardDeviation:
            var factor = 1.0
            if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRendererInputCell {
                factor = Double(cell.textField.text!) ?? 1
            }
            return AGSStandardDeviationStretchParameters(factor: factor)
        }
    }
    
    private func rendererParametersChanged() {
        delegate?.rgbRendererSettingsVC(self, didSelectStretchParameters: makeStretchParameters())
    }
    
    // MARK: - Actions
    
    @IBAction func textFieldAction(_ sender: UITextField) {
        rendererParametersChanged()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return the rows based on the stretch type selected
        switch self.stretchType {
        case .minMax, .percentClip:
            return 3
        case .standardDeviation:
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //first row cell is always RGBRendererStretchTypeCell
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RGBRendererStretchTypeCell", for: indexPath)
            stretchTypeCell = cell
            updateStretchTypeLabel()
            return cell
        } else {
            //load the rest of the cells based on the stretch type selected
            switch stretchType {
            case .minMax:
                 let cell = tableView.dequeueReusableCell(withIdentifier: "RGBRenderer3InputCell", for: indexPath) as! RGBRenderer3InputCell
                 switch indexPath.row {
                 case 1:
                    cell.leadingLabel.text = "Min"
                    updateCell(cell, for: minValues)
                 case 2:
                    cell.leadingLabel.text = "Max"
                    updateCell(cell, for: maxValues)
                 default:
                    break
                 }
                 return cell
            case .percentClip:
                let cell = tableView.dequeueReusableCell(withIdentifier: "RGBRendererInputCell", for: indexPath) as! RGBRendererInputCell
                switch indexPath.row {
                case 1:
                    cell.leadingLabel.text = "Min"
                    updateCell(cell, for: percentClipMin)
                case 2:
                    cell.leadingLabel.text = "Max"
                    updateCell(cell, for: percentClipMax)
                default:
                    break
                }
                return cell
            case .standardDeviation:
                let cell = tableView.dequeueReusableCell(withIdentifier: "RGBRendererInputCell", for: indexPath) as! RGBRendererInputCell
                cell.leadingLabel.text = "Factor"
                updateCell(cell, for: standardDeviationFactor)
                return cell
            }
        }
    }
    
    private let numberFormatter = NumberFormatter()
    
    private func updateCell(_ cell: RGBRenderer3InputCell, for values: [Double]) {
        if values.count >= 3 {
            cell.textField1.text = numberFormatter.string(from: values[0] as NSNumber)
            cell.textField2.text = numberFormatter.string(from: values[1] as NSNumber)
            cell.textField3.text = numberFormatter.string(from: values[2] as NSNumber)
        }
    }
    
    private func updateCell(_ cell: RGBRendererInputCell, for value: Double) {
        cell.textField.text = numberFormatter.string(from: value as NSNumber)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) == stretchTypeCell else {
            return
        }
        let labels = StretchType.allCases.map { $0.label }
        let selectedIndex = stretchType.rawValue
        let optionsViewController = OptionsTableViewController(labels: labels, selectedIndex: selectedIndex) { (newIndex) in
            self.stretchType = StretchType(rawValue: newIndex)!
            self.tableView.reloadData()
            self.rendererParametersChanged()
        }
        optionsViewController.title = "Stretch Type"
        show(optionsViewController, sender: self)
    }
}
