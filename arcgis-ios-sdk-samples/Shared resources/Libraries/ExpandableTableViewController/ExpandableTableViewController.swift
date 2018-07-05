//
// Copyright 2017 Esri.
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

import Foundation
import UIKit

class ExpandableTableViewController: UITableViewController {
    
    public var tableTitle: String?
    public var sectionHeaderTitles = [String]()
    public var sectionItems = [[(String, String)]]()

    private var expandedSectionHeaderNumber = -1
    private let kHeaderSectionTag = 7000;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the footer view
        tableView.tableFooterView = UIView()
        
        // Set title
        navigationItem.title = tableTitle
    }
    
    // MARK: - Table View Data Source Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if sectionHeaderTitles.count > 0 {
            tableView.backgroundView = nil
            return sectionHeaderTitles.count
        } else {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
            messageLabel.text = "Retrieving data.\nPlease wait..."
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont(name: "HelveticaNeue", size: 20.0)!
            messageLabel.sizeToFit()
            tableView.backgroundView?.backgroundColor = .white
            tableView.backgroundView = messageLabel;
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (expandedSectionHeaderNumber == section) {
            return sectionItems[section].count;
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (sectionHeaderTitles.count != 0) {
            return sectionHeaderTitles[section]
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0;
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        return 0;
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //
        // Recast view as a UITableViewHeaderFooterView
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = .white
        header.textLabel?.textColor = .primaryTextColor
        header.tag = section

        // Remove image view
        for subview in view.subviews {
            if subview is UIImageView {
                subview.removeFromSuperview()
            }
        }

        // Add image view
        let headerFrame = view.frame.size
        let imageView = UIImageView(frame: CGRect(x: headerFrame.width - 32, y: 13, width: 18, height: 18));
        if expandedSectionHeaderNumber == section {
            imageView.image = UIImage(named: "Expanded")
        }
        else {
            imageView.image = UIImage(named: "Collapsed")
        }
        imageView.tag = kHeaderSectionTag + section
        header.addSubview(imageView)
        
        // Add constraints for image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        header.addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: header, attribute: .centerY, multiplier: 1, constant: 0))
        header.addConstraint(NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: header, attribute: .trailing, multiplier: 1, constant: -16))
        
        // Make headers touchable
        let headerTapGesture = UITapGestureRecognizer()
        headerTapGesture.addTarget(self, action: #selector(sectionHeaderWasTouched(_:)))
        header.addGestureRecognizer(headerTapGesture)
        
        // Set border
        header.layer.borderColor = UIColor.lightGray.cgColor
        header.layer.borderWidth = 0.5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        let sectionData = sectionItems[indexPath.section]
        cell.textLabel?.textColor = .black
        let (text, detail) = sectionData[indexPath.row]
        cell.textLabel?.text = text
        cell.detailTextLabel?.text = detail
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Expand / Collapse Methods
    
    @objc func sectionHeaderWasTouched(_ sender: UITapGestureRecognizer) {
        let headerView = sender.view as! UITableViewHeaderFooterView
        let section    = headerView.tag
        let eImageView = headerView.viewWithTag(kHeaderSectionTag + section) as? UIImageView
        
        if (expandedSectionHeaderNumber == -1) {
            expandedSectionHeaderNumber = section
            tableViewExpandSection(section, imageView: eImageView!)
        } else {
            if (expandedSectionHeaderNumber == section) {
                tableViewCollapeSection(section, imageView: eImageView!)
            } else {
                let cImageView = view.viewWithTag(kHeaderSectionTag + expandedSectionHeaderNumber) as? UIImageView
                tableViewCollapeSection(expandedSectionHeaderNumber, imageView: cImageView!)
                tableViewExpandSection(section, imageView: eImageView!)
            }
        }
    }
    
    func tableViewCollapeSection(_ section: Int, imageView: UIImageView) {
        let sectionData = sectionItems[section]
        
        expandedSectionHeaderNumber = -1;
        if (sectionData.count == 0) {
            return;
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                imageView.image = UIImage(named: "Collapsed")
            })
            var indexesPath = [IndexPath]()
            for i in 0 ..< sectionData.count {
                let index = IndexPath(row: i, section: section)
                indexesPath.append(index)
            }
            tableView!.beginUpdates()
            tableView!.deleteRows(at: indexesPath, with: UITableViewRowAnimation.fade)
            tableView!.endUpdates()
        }
    }
    
    func tableViewExpandSection(_ section: Int, imageView: UIImageView) {
        let sectionData = sectionItems[section]
        
        if (sectionData.count == 0) {
            expandedSectionHeaderNumber = -1;
            return;
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                imageView.image = UIImage(named: "Expanded")
            })
            var indexesPath = [IndexPath]()
            for i in 0 ..< sectionData.count {
                let index = IndexPath(row: i, section: section)
                indexesPath.append(index)
            }
            expandedSectionHeaderNumber = section
            tableView!.beginUpdates()
            tableView!.insertRows(at: indexesPath, with: UITableViewRowAnimation.fade)
            tableView!.endUpdates()
        }
    }
}
