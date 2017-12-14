//
//  ExpandableTableViewController.swift
//  ExpandableTableView
//
//  Created by Nimesh Jarecha on 12/13/17.
//  Copyright © 2017 Nimesh Jarecha. All rights reserved.
//

import Foundation
import UIKit

class ExpandableTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    public var tableTitle: String?
    public var sectionHeaderTitles = [String]()
    public var sectionItems = [[String]]()
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet internal var tableNavigationItem: UINavigationItem!
    private var expandedSectionHeaderNumber = -1
    private var expandedSectionHeader: UITableViewHeaderFooterView!
    private let kHeaderSectionTag = 7000;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        tableNavigationItem.title = tableTitle
    }
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
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
            tableView.backgroundView = messageLabel;
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (expandedSectionHeaderNumber == section) {
            return sectionItems[section].count;
        } else {
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (sectionHeaderTitles.count != 0) {
            return sectionHeaderTitles[section]
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0;
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        return 0;
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //
        // Recast view as a UITableViewHeaderFooterView
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.white
        header.textLabel?.textColor = UIColor.primaryTextColor()
        
        if let viewWithTag = view.viewWithTag(kHeaderSectionTag + section) {
            viewWithTag.removeFromSuperview()
        }
        let headerFrame = view.frame.size
        let imageView = UIImageView(frame: CGRect(x: headerFrame.width - 32, y: 13, width: 18, height: 18));
        imageView.image = UIImage(named: "Collapsed")
        imageView.tag = kHeaderSectionTag + section
        header.addSubview(imageView)
        
        // Make headers touchable
        header.tag = section
        let headerTapGesture = UITapGestureRecognizer()
        headerTapGesture.addTarget(self, action: #selector(sectionHeaderWasTouched(_:)))
        header.addGestureRecognizer(headerTapGesture)
        
        // Set border
        header.layer.borderColor = UIColor.lightGray.cgColor
        header.layer.borderWidth = 0.5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as UITableViewCell
        let sectionData = sectionItems[indexPath.section]
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.text = sectionData[indexPath.row]
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
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
