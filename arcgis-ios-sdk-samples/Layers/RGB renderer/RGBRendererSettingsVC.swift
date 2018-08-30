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

class RGBRendererSettingsVC: UIViewController, UITableViewDataSource, RGBRendererTypeCellDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var stretchType:StretchType = .MinMax
    
    weak var delegate: RGBRendererSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return the rows based on the stretch type selected
        switch self.stretchType {
        case .MinMax, .PercentClip:
            return 3
        case .StandardDeviation:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //first row cell is always Row0
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Row0", for: indexPath) as! RGBRendererTypeCell
            cell.delegate = self
            return cell
        }
        //load the rest of the cells based on the stretch type selected
        else {
            if self.stretchType == .MinMax {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MinMaxRow\(indexPath.row)", for: indexPath)
                return cell
            }
            else if self.stretchType == .PercentClip {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PercentClipRow\(indexPath.row)", for: indexPath)
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "StandardDeviationRow1", for: indexPath)
                return cell
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func renderAction() {
        var stretchParameters:AGSStretchParameters
        
        //get the values from textFields in rows based on the selected stretch type
        if self.stretchType == .MinMax {
            var minValue1 = 0, minValue2 = 0, minValue3 = 0, maxValue1 = 255, maxValue2 = 255, maxValue3 = 255
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRenderer3InputCell {
                minValue1 = Int(cell.textField1.text!) ?? 0
                minValue2 = Int(cell.textField2.text!) ?? 0
                minValue3 = Int(cell.textField3.text!) ?? 0
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? RGBRenderer3InputCell {
                maxValue1 = Int(cell.textField1.text!) ?? 255
                maxValue2 = Int(cell.textField2.text!) ?? 255
                maxValue3 = Int(cell.textField3.text!) ?? 255
            }
            stretchParameters = AGSMinMaxStretchParameters(minValues: [NSNumber(value: minValue1), NSNumber(value: minValue2), NSNumber(value: minValue3)], maxValues: [NSNumber(value: maxValue1), NSNumber(value: maxValue2), NSNumber(value: maxValue3)])
        }
        else if self.stretchType == .PercentClip {
            var min = 0.0, max = 0.0
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRendererInputCell {
                min = Double(cell.textField.text!) ?? 0
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? RGBRendererInputCell {
                max = Double(cell.textField.text!) ?? 0
            }
            stretchParameters = AGSPercentClipStretchParameters(min: min, max: max)
        }
        else {
            var factor = 1.0
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? RGBRendererInputCell {
                factor = Double(cell.textField.text!) ?? 1
            }
            stretchParameters = AGSStandardDeviationStretchParameters(factor: factor)
        }
        //hide keyboard
        self.hideKeyboard()
        
        self.delegate?.rgbRendererSettingsVC(self, didSelectStretchParameters: stretchParameters)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    //MARK: - RGBRendererTypeCellDelegate
    
    //update view based on the stretch type
    func rgbRendererTypeCell(_ rgbRendererTypeCell: RGBRendererTypeCell, didUpdateType type: StretchType) {
        self.stretchType = type
        self.tableView.reloadData()
        
        let rows = self.tableView.numberOfRows(inSection: 0)
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.tableViewHeightConstraint.constant = CGFloat(rows * 44)
            self?.view.layoutIfNeeded()
            self?.view.superview?.superview?.layoutIfNeeded()
        }, completion: nil)
    }
}
