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

//constants for title, search bar placeholder text and data layer
let kViewTitle = "US Counties Info"
let kSearchBarPlaceholder = "Find Counties (e.g. Los Angeles)"
let kMapServiceLayerURL = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer/3"

class RootViewController: UITableViewController, AGSQueryTaskDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar:UISearchBar!
    
    var queryTask:AGSQueryTask!
    var query:AGSQuery!
    var featureSet:AGSFeatureSet!
    var detailsViewController:DetailsViewController!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //title for the navigation controller
        self.title = kViewTitle
        //text in search bar before user enters in query
        self.searchBar.placeholder = kSearchBarPlaceholder
        let countiesLayerURL = kMapServiceLayerURL
        
        //set up query task against layer, specify the delegate
        self.queryTask = AGSQueryTask(URL: NSURL(string: countiesLayerURL))
        self.queryTask.delegate = self
        
        //return all fields in query
        self.query = AGSQuery()
        self.query.outFields = ["*"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view methods
    
    //one section in this table
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //the section in the table is as large as the number of fetaures returned from the query
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.featureSet == nil {
            return 0
        }
        return self.featureSet.features.count ?? 0
    }
    
    //called by table view when it needs to draw one of its rows
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        //static instance to represent a single kind of cell. Used if the table has cells formatted differently
        let kRootViewControllerCellIdentifier = "RootViewControllerCellIdentifier"
        
        //as cells roll off screen get the reusable cell, if we can't create a new one
        var cell = tableView.dequeueReusableCellWithIdentifier(kRootViewControllerCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: kRootViewControllerCellIdentifier)
        }
        
        //get selected feature and extract the name attribute
        //display name in cell
        //add detail disclosure button. This will allow user to see all the attributes in a different view
        let feature = self.featureSet.features[indexPath.row] as! AGSGraphic
        cell?.textLabel?.text = feature.attributeAsStringForKey("NAME") //The display field name for the service we are using
        cell?.accessoryType = .DisclosureIndicator
        
        return cell!
    }
    
    //when a user selects a row (i.e. cell) in the table display all the selected features
    //attributes in a separate view controller
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        //if view controller not created, create it, set up the field names to display
        if nil == self.detailsViewController {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            self.detailsViewController = storyboard.instantiateViewControllerWithIdentifier("DetailsViewController") as! DetailsViewController
            self.detailsViewController.fieldAliases = self.featureSet.fieldAliases
            self.detailsViewController.displayFieldName = self.featureSet.displayFieldName
        }
        
        //the details view controller needs to know about the selected feature to get its value
        self.detailsViewController.feature = self.featureSet.features[indexPath.row] as! AGSGraphic
        
        //display the feature attributes
        self.navigationController?.pushViewController(self.detailsViewController, animated:true)
    }
    
    //MARK: - UISearchBarDelegate
    
    //when the user searches
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        //display busy indicator, get search string and execute query
        self.query.text = searchBar.text
        self.queryTask.executeWithQuery(self.query)
        
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - AGSQueryTaskDelegate
    
    //results are returned
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didExecuteWithFeatureSetResult featureSet: AGSFeatureSet!) {
        //get feature, and load in to table
        self.featureSet = featureSet
        self.tableView.reloadData()
    }
    
    //if there's an error with the query display it to the user
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
}
