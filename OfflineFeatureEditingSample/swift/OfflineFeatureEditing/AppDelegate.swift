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

import UIKit
import ArcGIS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var splitViewController:UISplitViewController?
    
    var logPath:String?
    
    func logAppStatus(status:String) {
        //If we don't already have a log file path, lets set one up
        if self.logPath == nil {
            var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            var path = paths[0] as String
            self.logPath = path.stringByAppendingPathComponent("appLog.txt")
        }
        
        //write to the file
        var logFileHandle:NSFileHandle? = NSFileHandle(forWritingAtPath: self.logPath!)
        if logFileHandle != nil {
            logFileHandle!.seekToEndOfFile()
            logFileHandle!.writeData(status.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        }
        else {
            //have to create the file
            status.writeToFile(self.logPath!, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    //This will get called periodically by the system when the app is background'ed if
    //the app declares it supports "Background Fetch" capability in XCode project settings
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        BackgroundHelper.checkJobStatusInBackground(completionHandler)
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        BackgroundHelper.downloadJobResultInBackgroundWithURLSession(identifier, completionHandler: completionHandler)
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
}

