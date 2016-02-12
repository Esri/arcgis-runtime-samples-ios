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

class MessageHelper {
   
    class func extractMostRecentMessage(messages:[AGSGPMessage]) -> String? {
        let description = messages[messages.count-1].description
        if let range = description.rangeOfString("description: ", options: NSStringCompareOptions.LiteralSearch, range: nil, locale: nil) {
            var message:String!
            
            if !range.isEmpty {
                message = description.substringFromIndex(range.endIndex)
            }
            else{
                message = description
            }
            
            if messages.count > 1 {
                let detailsMessages = messages[messages.count-2]
                let percentageString = detailsMessages.description
                if let range = percentageString.rangeOfString("Finished:: ", options: NSStringCompareOptions.LiteralSearch, range: nil, locale: nil) {
                
                    if !range.isEmpty {
                        var substring = percentageString.substringFromIndex(range.endIndex) as String
                        substring = substring.stringByReplacingOccurrencesOfString(" percent", withString: "", options: .CaseInsensitiveSearch, range: nil)
                        message = message.stringByAppendingString(" (\(substring)% completed)")
                    }
                }
            }
            return message;
        }
        return nil
    }
}
