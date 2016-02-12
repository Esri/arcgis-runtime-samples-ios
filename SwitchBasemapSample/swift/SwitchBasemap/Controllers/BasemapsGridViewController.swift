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
import ArcGIS

class BasemapsGridViewController:UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PortalBasemapHelperDelegate, UICollectionViewDelegateFlowLayout {
    
    //shared instance of the helper class
    var portalBasemapHelper = PortalBasemapHelper.sharedInstance
    //delegate that handles the selection actions
    weak var delegate:BasemapPickerDelegate?
    //collection for the list of webmaps
    @IBOutlet weak var collectionView: UICollectionView!
    
    //hide the status bar for this view controller
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        //assign the helper delegate as self
        self.portalBasemapHelper.delegate = self
        //fetch the webmaps if not already present
        if self.portalBasemapHelper.webmapsArray.count == 0 {
            showHUDWithStatus("Loading")
            self.portalBasemapHelper.fetchWebmaps(kPortalUrl, credential: nil)
        }
    }
    
    //MARK: Collection view data source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //if there are more results, then add an extra item for the indicator
        if self.portalBasemapHelper.hasMoreResults() {
            return self.portalBasemapHelper.webmapsArray.count+1
        }
        return self.portalBasemapHelper.webmapsArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        //item cell for next results
        if self.portalBasemapHelper.hasMoreResults() && indexPath.item == self.portalBasemapHelper.webmapsArray.count {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LoadCell", forIndexPath: indexPath) 
            return cell
        }
        //item cell for the regular data
        else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionCell", forIndexPath: indexPath) 
            
            let portalItem = self.portalBasemapHelper.webmapsArray[indexPath.item] as AGSPortalItem
            //use thumbnail image if present or else use the placeholder image
            let thumbnailView = cell.viewWithTag(1) as! UIImageView
            if portalItem.thumbnail != nil {
                thumbnailView.image = portalItem.thumbnail
            }
            else {
                thumbnailView.image = UIImage(named: "Placeholder")
            }
            
            //use the portal item title as the label
            let label = cell.viewWithTag(2) as! UILabel
            label.text = portalItem.title
            
            return cell
        }
    }
    
    //MARK: Collection view delegates
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let portalItem = self.portalBasemapHelper.webmapsArray[indexPath.item] as AGSPortalItem
        //check if a cached version of the basemap exists
        //if yes, then notify the delegate of the selection
        //else start the download process for the basemap
        if let basemap = self.portalBasemapHelper.cachedBasemap(forItemId: portalItem.itemId) {
            self.delegate?.basemapPickerController(self, didSelectBasemap: basemap)
        }
        else {
            self.portalBasemapHelper.cacheBasemap(forPortalItem:portalItem)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        //for displaying three items in a row
        let width = (self.collectionView.frame.size.width - 40)/3.0
        return CGSizeMake(width, width)
    }
    
    //MARK: Portal basemap helper delegates
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFailWithError error: NSError) {
        dismissHUD()
        //display all the errors from the helper class in an alert view
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFetchThumbnail thumbnail: UIImage, forPortalItem portalItem: AGSPortalItem) {
        //find the index of the portalItem in the array
        if let index = self.portalBasemapHelper.webmapsArray.indexOf(portalItem) {
            //get the array of visible cells
            let visibleCells = self.collectionView.visibleCells()
            //get the cell corresponding to the index
            if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) {            
                //check if the cell is visible
                let isVisible = visibleCells.contains(cell)
                //if visible update the image
                if isVisible {
                    self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                }
            }
        }
    }
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFinishCachingBasemap basemap: AGSWebMapBaseMap, forWebMap webMap: AGSWebMap)  {
        //notify the delegate of the selection
        self.delegate?.basemapPickerController(self, didSelectBasemap: basemap)
    }
    
    func portalBasemapHelper(portalBasemapHelper: PortalBasemapHelper, didFinishLoadingPortalItems portalItems: [AGSPortalItem])  {
        //reload the data
        self.collectionView.reloadData()
        dismissHUD()
    }
    
    //MARK: actions
    
    @IBAction func cancelAction(sender: AnyObject) {
        //notify the delegate to hide the controller when tapped on cancel
        self.delegate?.basemapPickerControllerDidCancel(self)
    }
    
    @IBAction func loadMoreResults(sender: AnyObject) {
        showHUDWithStatus("Loading")
        //load next set of results when tapped on the special cell
        self.portalBasemapHelper.fetchNextResults()
    }
    
    //MARK: Interface rotation
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        //update the layout everytime the device rotates
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}
