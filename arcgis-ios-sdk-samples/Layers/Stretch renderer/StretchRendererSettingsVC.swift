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

enum StretchType: String {
    case MinMax = "MinMax"
    case PercentClip = "PercentClip"
    case StandardDeviation = "StdDeviation"
    
    static let allValues = [MinMax.rawValue, PercentClip.rawValue, StandardDeviation.rawValue]
    
    init?(id: Int) {
        switch id {
        case 0:
            self = .MinMax
        case 1:
            self = .PercentClip
        case 2:
            self = .StandardDeviation
        default:
            return nil
        }
    }
}

protocol StretchRendererSettingsVCDelegate: AnyObject {
    
    func stretchRendererSettingsVC(_ stretchRendererSettingsVC: StretchRendererSettingsVC, didSelectStretchParameters parameters: AGSStretchParameters)
}

class StretchRendererSettingsVC: UIViewController, UITableViewDataSource, StretchRendererTypeCellDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var stretchType:StretchType = .MinMax
    
    weak var delegate: StretchRendererSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.stretchType {
        case .MinMax, .PercentClip:
            return 3
        case .StandardDeviation:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Row0", for: indexPath) as! StretchRendererTypeCell
            cell.delegate = self
            return cell
        }
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
        
        if self.stretchType == .MinMax {
            var minValue = 0, maxValue = 255
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                minValue = Int(cell.textField.text!) ?? 0
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? StretchRendererInputCell {
                maxValue = Int(cell.textField.text!) ?? 255
            }
            stretchParameters = AGSMinMaxStretchParameters(minValues: [NSNumber(value: minValue)], maxValues: [NSNumber(value: maxValue)])
        }
        else if self.stretchType == .PercentClip {
            var min = 0.0, max = 0.0
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                min = Double(cell.textField.text!) ?? 0
            }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? StretchRendererInputCell {
                max = Double(cell.textField.text!) ?? 0
            }
            stretchParameters = AGSPercentClipStretchParameters(min: min, max: max)
        }
        else {
            var factor = 1.0
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? StretchRendererInputCell {
                factor = Double(cell.textField.text!) ?? 1
            }
            stretchParameters = AGSStandardDeviationStretchParameters(factor: factor)
        }
        //hide keyboard
        self.hideKeyboard()
        
        self.delegate?.stretchRendererSettingsVC(self, didSelectStretchParameters: stretchParameters)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    //MARK: - StretchRendererTypeCellDelegate
    
    func stretchRendererTypeCell(_ stretchRendererTypeCell: StretchRendererTypeCell, didUpdateType type: StretchType) {
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
