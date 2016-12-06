// Copyright 2016 Esri.
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    private var indexArray:[String]!
    private var wordsDictionary:[String: [String]]!
    private var readmeDirectoriesURLs:[NSURL]!

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.absoluteString!.rangeOfString("auth", options: [], range: nil, locale: nil) != nil {
            AGSApplicationDelegate.sharedApplicationDelegate().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        }
        return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self
        
        //min max width for master
        splitViewController.minimumPrimaryColumnWidth = 320
        splitViewController.maximumPrimaryColumnWidth = 320
        
        self.modifyAppearance()
        
        //enable/disable touches based on settings
        self.setTouchPref()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.setTouchPref()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: - Touch settings
    
    func setTouchPref() {
        //enable/disable touches based on settings
        let bool = NSUserDefaults.standardUserDefaults().boolForKey("showTouch")
        if bool {
            DemoTouchManager.showTouches()
            DemoTouchManager.touchBorderColor = UIColor.lightGrayColor()
            DemoTouchManager.touchFillColor = UIColor(white: 231/255.0, alpha: 1)
        }
        else {
            DemoTouchManager.hideTouches()
        }
    }
    
    
    // MARK: - Appearance modification
    
    func modifyAppearance() {
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        UINavigationBar.appearance().barTintColor = UIColor.primaryBlue()
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
        UIToolbar.appearance().barTintColor = UIColor.backgroundGray()
        UIToolbar.appearance().tintColor = UIColor.primaryBlue()
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if secondaryViewController.restorationIdentifier == "DetailNavigationController" {
            return true
        }
        else {
            return false
        }
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if let navigationController = primaryViewController as? UINavigationController {
            if navigationController.topViewController! is ContentCollectionViewController || navigationController.topViewController is ContentTableViewController {
                
                let controller = splitViewController.storyboard!.instantiateViewControllerWithIdentifier("DetailNavigationController") as! UINavigationController
                controller.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
                controller.topViewController!.navigationItem.leftItemsSupplementBackButton = true
                return controller
            }
        }
        return nil
    }
}

extension UIColor {
    class func primaryBlue() -> UIColor {
        return UIColor(red: 0, green: 0.475, blue: 0.757, alpha: 1)
    }
    
    class func secondaryBlue() -> UIColor {
        return UIColor(red: 0, green: 0.368, blue: 0.584, alpha: 1)
    }
    
    class func backgroundGray() -> UIColor {
        return UIColor(red: 0.973, green: 0.973, blue: 0.973, alpha: 1)
    }
    
    class func primaryTextColor() -> UIColor {
        return UIColor(red: 0.196, green: 0.196, blue: 0.196, alpha: 1)
    }
    
    class func secondaryTextColor() -> UIColor {
        return UIColor(red: 0.349, green: 0.349, blue: 0.349, alpha: 1)
    }
}

