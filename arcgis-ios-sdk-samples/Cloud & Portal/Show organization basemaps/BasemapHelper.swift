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

import UIKit
import ArcGIS

class BasemapHelper: NSObject {
    
    static let shared:BasemapHelper = BasemapHelper()
    
    private override init() {}
    
    var basemaps:[AGSPortalItem]!
    var resultSet:AGSPortalQueryResultSet!
    
    private var portal:AGSPortal!
    
    //to fetch basemaps from the portal (first 5 basemaps will be fetched)
    func fetchBasemaps(from portal:AGSPortal, completion: @escaping ((_ error: Error?) -> Void)) {
        //if its the same portal
        if portal.url == self.portal?.url {
            
            if self.basemaps.count > 0 {
                //if basemaps are available then use them
                completion(nil)
            }
            else {
                //else download
                self.fetchBasemapsGroup(completion: completion)
            }
        }
        else {
            //clear everything and download
            self.basemaps = [AGSPortalItem]()
            self.portal = portal
            
            self.fetchBasemapsGroup(completion: completion)
        }
    }
    
    //to fetch the next set of basemaps from the portal
    func fetchMoreBasemaps(completion: @escaping ((_ error: Error?) -> Void)) {
        
        //if the nextQueryParameters property on resultSet is not nil 
        //then there are more basemaps available
        if let nextQueryParameters = self.resultSet?.nextQueryParameters {
            
            self.fetchBasemaps(nextQueryParameters, completion: completion)
        }
        else {
            //error
            let userInfo = [NSLocalizedDescriptionKey: "No more basemaps available"]
            let error = NSError(domain: "com.esri.BasemapHelper", code: 101, userInfo: userInfo)
            completion(error)
        }
    }
    
    //get the group to query for basemaps in the specified portal
    private func fetchBasemapsGroup(completion: @escaping ((_ error: Error?) -> Void)) {
        
        //get the basemap group query from portal info
        if let queryString = self.portal.portalInfo?.basemapGalleryGroupQuery {
            
            //initialize query parameters with that query string
            let queryParameters = AGSPortalQueryParameters(query: queryString)
            
            //initiate find
            self.portal.findGroups(with: queryParameters) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: Error?) in
                
                if let error = error {
                    //call completion with error
                    completion(error)
                }
                else {
                    if let basemapsGroup = resultSet?.results?[0] as? AGSPortalGroup {
                        
                        //initialize query
                        let queryParameters = AGSPortalQueryParameters(forItemsInGroup: "\(basemapsGroup.groupID!)")
                        
                        //query for basemaps in the group
                        self?.fetchBasemaps(queryParameters, completion: completion)
                    }
                }
            }
        }
        else {
            //if basemapGalleryGroupQuery is nil, call completion with custom error
            let userInfo = [NSLocalizedDescriptionKey: "Portal group for basemaps not found"]
            let error = NSError(domain: "com.esri.BasemapHelper", code: 102, userInfo: userInfo)
            completion(error)
        }
    }
    
    private func fetchBasemaps(_ queryParameters: AGSPortalQueryParameters, completion: @escaping ((_ error: Error?) -> Void)) {
        
        //to demo paging restricting to 5 basemaps per query or fetch
        queryParameters.limit = 5
        
        //initiate find items
        self.portal.findItems(with: queryParameters) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: Error?) in
            if let error = error {
                completion(error)
            }
            else {
                if let basemaps = resultSet?.results as? [AGSPortalItem] {
                    
                    //append the resulting basemaps to the array
                    self?.basemaps.append(contentsOf: basemaps)
                    
                    //keep a reference to the resultSet for next query (fetchMoreBasemaps)
                    self?.resultSet = resultSet!
                    
                    //call completion
                    completion(nil)
                }
            }
        }
    }
}
