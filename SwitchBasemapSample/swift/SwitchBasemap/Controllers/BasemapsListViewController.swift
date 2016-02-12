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

import Foundation
import UIKit
import ArcGIS

class BasemapsListViewController:UIViewController, UITableViewDataSource, UITableViewDelegate, PortalBasemapHelperDelegate {
    
    //shared instance of the helper class
    var portalBasemapHelper = PortalBasemapHelper.sharedInstance
    //delegate that handles selection actions
    weak var delegate:BasemapPickerDelegate?
    //footer view to provide feedback if there are more webmaps
    @IBOutlet weak var footerView: UIView!
    //to list the webmaps
    @IBOutlet weak var tableView: UITableView!
    
    
    //to hide the status bar when presenting this view controller
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        //assign the delegate as self for helper class
        portalBasemapHelper.delegate = self
        //if webmaps not already present, call the method on the helper class
        if portalBasemapHelper.webmapsArray.count == 0 {
            showHUDWithStatus("Loading")
            portalBasemapHelper.fetchWebmaps(kPortalUrl, credential: nil)
        }
    }
    
    //MARK: footer view methods
    
    //to hide the footer view
    func hideFooterView() {
        self.footerView.hidden = true
    }
    //to show the footer view
    func showFooterView() {
        self.footerView.hidden = false
    }
    
    //MARK: table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //check if there are more results and hide/show the footer view accordingly
        if self.portalBasemapHelper.hasMoreResults() {
            self.showFooterView()
        }
        else {
            self.hideFooterView()
        }
        
       return portalBasemapHelper.webmapsArray.count;
    }
    
    //using the title of the portal item as the label, snippet for description and thumbnail as image view
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TableCell")!
        
        let webmap = portalBasemapHelper.webmapsArray[indexPath.row]
        
        let titleLabel = cell.viewWithTag(2) as! UILabel
        titleLabel.text = webmap.title
        
        let descriptionLabel = cell.viewWithTag(3) as! UILabel
        descriptionLabel.text = webmap.snippet
        
        let thumbnailImageView = cell.viewWithTag(1) as! UIImageView
        //Use the thumbnail image if there else use the placeholder image
        if webmap.thumbnail != nil {
            thumbnailImageView.image = webmap.thumbnail
        }
        else {
            thumbnailImageView.image = UIImage(named: "Placeholder")
        }
        
        return cell
    }
    
    //MARK: table view delegates
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let portalItem = self.portalBasemapHelper.webmapsArray[indexPath.row]
        //check if there is a cached version of the basemap
        //if yes, then notify the delegate
        //else initiate the process for downloading and caching the basemap
        if let basemap = self.portalBasemapHelper.cachedBasemap(forItemId: portalItem.itemId) {
            self.delegate?.basemapPickerController(self, didSelectBasemap: basemap)
        }
        else {
            self.portalBasemapHelper.cacheBasemap(forPortalItem:portalItem)
        }
    }
    
    //MARK: portal basemap helper delegates
    
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFailWithError error: NSError) {
        dismissHUD()
        //display any error from the helper class in the alert view
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFinishLoadingPortalItems portalItems:[AGSPortalItem]) {
        self.tableView.reloadData()
        
        dismissHUD()
    }
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFetchThumbnail thumbnail: UIImage, forPortalItem portalItem: AGSPortalItem) {
        //find the index of the portalItem in the array
        
        if let index = self.portalBasemapHelper.webmapsArray.indexOf(portalItem) {
            //get the array of visible cells
            let visibleCells = self.tableView.visibleCells
            //get the cell corresponding to the index
            if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                //check if the cell is visible
                let isVisible = visibleCells.contains(cell)
                //and if visible then update the image
                if isVisible {
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation:.None)
                }
            }
        }
    }
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFinishCachingBasemap basemap: AGSWebMapBaseMap, forWebMap webMap: AGSWebMap)  {
        //notify the delegate about the selected basemap
        self.delegate?.basemapPickerController(self, didSelectBasemap: basemap)
    }
    
    //MARK: actions
    
    //notify the delegate to hide the controller if tapped on cancel
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        self.delegate?.basemapPickerControllerDidCancel(self)
    }
    
    //fetch next results if tapped on more
    @IBAction func loadMoreResults(sender:AnyObject) {
        showHUDWithStatus("Loading")
        self.portalBasemapHelper.fetchNextResults()
    }
}