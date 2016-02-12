//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

// A protocol to update the delegate on what unit was selected
protocol UnitSelectorViewDelegate:class {

    // A method update the distance unit
    func didSelectDistanceUnit(unit:AGSSRUnit)
    
    // A method to update the area units
    func didSelectAreaUnit(unit:AGSAreaUnits)
}

class UnitSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView:UITableView!
    var distanceUnits:[AGSSRUnit]!
    var areaUnits:[AGSAreaUnits]!
    var useAreaUnits:Bool = false
    
    weak var delegate:UnitSelectorViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.modalPresentationStyle = .FormSheet
        
        // Create the data sources for the table view with the different unit options
        self.distanceUnits = [AGSSRUnit.UnitSurveyMile, AGSSRUnit.UnitSurveyYard, AGSSRUnit.UnitSurveyFoot, AGSSRUnit.UnitKilometer, AGSSRUnit.UnitMeter]
        
        self.areaUnits = [AGSAreaUnits.SquareMiles, AGSAreaUnits.Acres, AGSAreaUnits.SquareYards, AGSAreaUnits.SquareKilometers, AGSAreaUnits.SquareMeters]
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.grayColor()
    }

//    override func viewWillAppear(animated: Bool) {
//        self.tableView.reloadData()
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kCustomCellID = "MyCellID"
        
        // Create a cell
        var cell = tableView.dequeueReusableCellWithIdentifier(kCustomCellID)
        if (cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: kCustomCellID)
//            cell?.textLabel?.textColor = UIColor.whiteColor()
            cell?.textLabel?.backgroundColor = UIColor.whiteColor()
        }
        
        // Set the text according to the unit option
        if !self.useAreaUnits {
            
            let currentUnit = self.distanceUnits[indexPath.row]
            
            switch currentUnit {
            case .UnitSurveyMile:
                cell?.textLabel?.text = "Miles"
            case .UnitSurveyYard:
                cell?.textLabel?.text = "Yards"
            case .UnitSurveyFoot:
                cell?.textLabel?.text = "Feet"
            case .UnitKilometer:
                cell?.textLabel?.text = "Kilometers"
            case .UnitMeter:
                cell?.textLabel?.text = "Meters"
            default:
                break
            }
        }
        else {
            let currentUnit = self.areaUnits[indexPath.row]
            
            switch currentUnit {
            case .SquareMiles:
                cell?.textLabel?.text = "Square Miles"
            case .Acres:
                cell?.textLabel?.text = "Acres"
            case .SquareYards:
                cell?.textLabel?.text = "Square Yards"
            case .SquareKilometers:
                cell?.textLabel?.text = "Square Kilometers"
            case .SquareMeters:
                cell?.textLabel?.text = "Square Meters"
            default:
                break
            }
        }
        
        return cell!
    }
    
    //MARK: - table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // When a row is tapped call the delegate method to update the units
        if !self.useAreaUnits {
            self.delegate?.didSelectDistanceUnit(self.distanceUnits[indexPath.row])
        }
        else {
            self.delegate?.didSelectAreaUnit(self.areaUnits[indexPath.row])
        }
    }
}
