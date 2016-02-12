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

protocol PortalBasemapHelperDelegate: class {
    /** Tells the delegate that an error was encountered either while loading portal, group, portalItem or images.
    @param portalBasemapHelper  Instance of the PortalBasemapHelper
    @param error                Information about the cause of the failure.
    **/
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFailWithError error: NSError)
    /** Tells the delegate that the portal items were loaded successfully
    @param portalBasemapHelper  Instance of the PortalBasemapHelper
    @param portalItems          List of portalItems that were loaded in the current request
    **/
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFinishLoadingPortalItems portalItems:[AGSPortalItem])
    /** Tells the delegate that the image for the portalItem was loaded successfully
    @param portalBasemapHelper  Instance of the PortalBasemapHelper
    @param thumbnail            Image that was loaded
    @param portalItem           PortalItem for which the image was loaded
    **/
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFetchThumbnail thumbnail:UIImage, forPortalItem portalItem:AGSPortalItem)
    /** Tells the delegate that the basemap was successfully cached
    @param portalBasemapHelper  Instance of the PortalBasemapHelper
    @param basemap              Basemap which was cached
    @param webMap               WebMap for which the basemap was cached
    **/
    func portalBasemapHelper(portalBasemapHelper:PortalBasemapHelper, didFinishCachingBasemap basemap:AGSWebMapBaseMap, forWebMap webMap:AGSWebMap)
}

class PortalBasemapHelper: NSObject, AGSPortalDelegate, AGSPortalItemDelegate, AGSWebMapDelegate {
    
    /** The portal that will be used to fetch items
    **/
    var portal:AGSPortal!
    
    /** The delegate for the PortalBasemapHelper operations
    **/
    weak var delegate:PortalBasemapHelperDelegate?
    
    /** The array to store the list of portalItems fetched from the portal
    **/
    var webmapsArray = [AGSPortalItem]()
    
    /** The resultSet from the last response, used to predict if there are more results
    **/
    var latestResultSet:AGSPortalQueryResultSet!
    
    /** The dictionary used to cached basemaps
    **/
    var basemapDictionary = [String: AGSWebMapBaseMap]()
    
    /** The web map that was selected as a source for the basemap
    **/
    var selectedWebMap:AGSWebMap!
    
    /** Provides a shared instance of the class. That helps keep the already loaded portal items,
        and serve both grid and list views the same time.
        :: If using as a data source with multiple views, make sure the delegate is assigned correctly
        to the class currently active
    **/
    class var sharedInstance:PortalBasemapHelper {
        struct Static {
            static var instance:PortalBasemapHelper!
            static var token:dispatch_once_t = 0
        }
            
        dispatch_once(&Static.token) {
            Static.instance = PortalBasemapHelper()
        }
        return Static.instance
    }
    
    //MARK: Internal methods
    
    /** Method to fetch the webmaps from a portal. Creates a portal object using the url and credential provided. Once the portal is
        loaded, a query for the basemaps group is sent and on success the items in the group are query'ed and the result is sent to
        delegate
    @param portalURL    String containing the url for the portal
    @param credential   The credential used to login to the portal, if required
    **/
    internal func fetchWebmaps(portalURL:NSString, credential:AGSCredential?) {
        self.portal = AGSPortal(URL: NSURL(string:portalURL as String), credential: credential)
        self.portal.delegate = self
    }
    
    /** Based on the resultSet of the previous response checks if there are more portal items
    **/
    internal func hasMoreResults() -> Bool {
        if (self.latestResultSet != nil) {
            if (self.latestResultSet.nextQueryParams != nil) {
                return true
            }
        }
        return false
    }
    
    /** Fetches the next set of results based on the query param received in the previous response
    **/
    internal func fetchNextResults() {
        if hasMoreResults() {
            self.portal.findItemsWithQueryParams(self.latestResultSet.nextQueryParams)
        }
    }
    
    //MARK: Caching basemaps
    
    /** Checks if there is a cached version of the basemap for the specified itemId
    @param itemId   The itemId for the webMap, for which the basemap is required
    @return         Basemap if exists, else nil
    **/
    internal func cachedBasemap(forItemId itemId:String) -> AGSWebMapBaseMap? {
        let basemap = self.basemapDictionary[itemId]
        return basemap
    }
    
    /** Kicks off the process for caching basemap for the specified portalItem. This involves instantiating
        the portalItem as a webmap and extracting the basemap on successful load.
    @param portalItem   The portalItem or webmap for which the basemap needs to be cached
    **/
    internal func cacheBasemap(forPortalItem portalItem:AGSPortalItem) {
        selectedWebMap = AGSWebMap(portalItem: portalItem)
        selectedWebMap.delegate = self
    }
    
    //MARK: Private methods
    
    /** Fires a query for the basemapGalleryGroup to the portal
    **/
    private func findBasemapGroup() {
        let queryParams = AGSPortalQueryParams(query: self.portal!.portalInfo.basemapGalleryGroupQuery)
        self.portal.findGroupsWithQueryParams(queryParams)
    }
    
    /** Fires a query for the items in the specified group
    @param groupId  The id of the group for which the items are to be fetched
    **/
    private func fetchBasemaps(fromGroupId groupId:String) {
        let queryParams = AGSPortalQueryParams(forItemsInGroup: groupId)
        queryParams.limit = 4
        self.portal.findItemsWithQueryParams(queryParams)
    }
    
    /** Returns an array of portalItems that are only web maps
    @param results  The list of portal items received from the portal
    @return         The list of portal items that are only web maps
    **/
    private func filterOutWebmaps(results:[AGSPortalItem]) -> [AGSPortalItem] {
        var webmapsArray = [AGSPortalItem]();
        for portalItem in results {
            if portalItem.type == AGSPortalItemType.WebMap {
                webmapsArray.append(portalItem)
            }
        }
        return webmapsArray;
    }
    
    /** Kicks off thumbnail download request for the portal items
    @param items    List of portalItems
    **/
    private func downloadThumbnails(forItems items:[AGSPortalItem]) {
        for portalItem:AGSPortalItem in items {
            portalItem.delegate = self
            
            if portalItem.thumbnail == nil {
                portalItem.fetchThumbnail()
            }
        }
    }
    
    //MARK: portal delegate methods
    
    /** if portal failed to load, notify the delegate with the error details
    **/
    func portal(portal: AGSPortal!, didFailToLoadWithError error: NSError!) {
        self.delegate?.portalBasemapHelper(self, didFailWithError: error)
    }
    
    /** else query the portal for the BasemapGalleryGroup
    **/
    func portalDidLoad(portal: AGSPortal!) {
        findBasemapGroup()
    }
    
    /** if portal failed to find the group, notify the delegate with the error details
    **/
    func portal(portal: AGSPortal!, operation: NSOperation!, didFailToFindGroupsForQueryParams queryParams: AGSPortalQueryParams!, withError error: NSError!) {
        self.delegate?.portalBasemapHelper(self, didFailWithError: error)
    }
    
    /** else query the group for its items
    **/
    func portal(portal: AGSPortal!, operation: NSOperation!, didFindGroups resultSet: AGSPortalQueryResultSet!) {
        if resultSet.results.count > 0 {
            let group:AGSPortalGroup = resultSet.results[0] as! AGSPortalGroup
            fetchBasemaps(fromGroupId: group.groupId)
        }
        else {
            print("basemap group not found");
        }
    }
    
    /** if portal failed to find items in the group, notify the delegate with the error details
    **/
    func portal(portal: AGSPortal!, operation: NSOperation!, didFailToFindItemsForQueryParams queryParams: AGSPortalQueryParams!, withError error: NSError!) {
        self.delegate?.portalBasemapHelper(self, didFailWithError: error)
    }
    
    /** else update the latestResultSet values, filter out the results for just webmaps, append the web maps in
        case if it was a request for next results, start downloading the thumbnails and notify the delegate
    **/
    func portal(portal: AGSPortal!, operation: NSOperation!, didFindItems resultSet: AGSPortalQueryResultSet!) {

        //update the value
        self.latestResultSet = resultSet;
        
        //filter out just webmaps
        let webmaps = filterOutWebmaps(resultSet.results as! [AGSPortalItem])
        
        if self.webmapsArray.count > 0 {
            self.webmapsArray += webmaps
        }
        else {      //append the webmaps if it was a request for next results
            self.webmapsArray = webmaps
        }
        
        //start downloading thumbnails
        self.downloadThumbnails(forItems: webmaps)
        
        //notify the delegate
        self.delegate?.portalBasemapHelper(self, didFinishLoadingPortalItems:webmaps)
    }
    
    //MARK: portal item delegate 
    
    /** If failed to fetch the thumbail, forward the error details to the delegate
    **/
    func portalItem(portalItem: AGSPortalItem!, operation op: NSOperation!, didFailToFetchThumbnailWithError error: NSError!) {
        self.delegate?.portalBasemapHelper(self, didFailWithError: error)
    }
    
    /** else if successful, forward the thumbnail and portal item
    **/
    func portalItem(portalItem: AGSPortalItem!, operation op: NSOperation!, didFetchThumbnail thumbnail: UIImage!) {
        self.delegate?.portalBasemapHelper(self, didFetchThumbnail: thumbnail, forPortalItem: portalItem)
    }
    
    //MARK: web map delegates
    
    /** If the web map loaded successfully, cache the basemap in the dictionary
        and update the delegate
    **/
    func webMapDidLoad(webMap: AGSWebMap!) {
        //add the basemap to the cache
        self.basemapDictionary[webMap.portalItem.itemId] = webMap.baseMap
        //call the delegate
        self.delegate?.portalBasemapHelper(self, didFinishCachingBasemap: webMap.baseMap, forWebMap: webMap)
    }
    
    /** Else forward the error details to the delegate
    **/
    func webMap(webMap: AGSWebMap!, didFailToLoadWithError error: NSError!) {
        self.delegate?.portalBasemapHelper(self, didFailWithError: error)
    }
}