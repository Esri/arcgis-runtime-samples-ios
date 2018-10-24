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
    
    weak var stretchTypeCell: RGBRendererStretchTypeCell?
    
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
    
    private var stretchType: RGBRendererSettingsVC.StretchType = .minMax {
        didSet{
            updateStretchTypeLabel()
        }
    }
    private func updateStretchTypeLabel(){
        stretchTypeCell?.stretchTypeLabel.text = stretchType.label
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
            return AGSMinMaxStretchParameters(minValues: [NSNumber(value: minValue1), NSNumber(value: minValue2), NSNumber(value: minValue3)], maxValues: [NSNumber(value: maxValue1), NSNumber(value: maxValue2), NSNumber(value: maxValue3)])
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
    
    //MARK: - Actions
    
    @IBAction func textFieldAction(_ sender: UITextField) {
        rendererParametersChanged()
    }
    
    //MARK: - UITableViewDataSource
    
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "RGBRendererStretchTypeCell", for: indexPath) as! RGBRendererStretchTypeCell
            stretchTypeCell = cell
            updateStretchTypeLabel()
            return cell
        }
        else {
            //load the rest of the cells based on the stretch type selected
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
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) is RGBRendererStretchTypeCell else {
            return
        }
        let labels = StretchType.allCases.map({ (type) -> String in
            return type.label
        })
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
