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

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteString.range(of: "auth", options: [], range: nil, locale: nil) != nil {
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self
        
        //min max width for master
        splitViewController.minimumPrimaryColumnWidth = 320
        splitViewController.maximumPrimaryColumnWidth = 320
        
        self.modifyAppearance()
        
        //enable/disable touches based on settings
        self.setTouchPref()
        
        SVProgressHUD.setDefaultMaskType(.gradient)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.setTouchPref()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: - Touch settings
    
    func setTouchPref() {
        //enable/disable touches based on settings
        let bool = UserDefaults.standard.bool(forKey: "showTouch")
        if bool {
            DemoTouchManager.showTouches()
            DemoTouchManager.touchBorderColor = .lightGray
            DemoTouchManager.touchFillColor = UIColor(white: 231/255.0, alpha: 1)
        }
        else {
            DemoTouchManager.hideTouches()
        }
    }
    
    
    // MARK: - Appearance modification
    
    func modifyAppearance() {
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        UINavigationBar.appearance().barTintColor = .primaryBlue
        UINavigationBar.appearance().tintColor = .white
        
        UIToolbar.appearance().barTintColor = .backgroundGray
        UIToolbar.appearance().tintColor = .primaryBlue
        
        UISwitch.appearance().onTintColor = .primaryBlue
        UISlider.appearance().tintColor = .primaryBlue
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        if secondaryViewController.restorationIdentifier == "DetailNavigationController" {
            return true
        }
        else {
            return false
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let navigationController = primaryViewController as? UINavigationController {
            if navigationController.topViewController! is ContentCollectionViewController || navigationController.topViewController is ContentTableViewController {
                
                let controller = splitViewController.storyboard!.instantiateViewController(withIdentifier: "DetailNavigationController") as! UINavigationController
                controller.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                controller.topViewController!.navigationItem.leftItemsSupplementBackButton = true
                return controller
            }
        }
        return nil
    }
}

extension UIColor {
    class var primaryBlue: UIColor { return #colorLiteral(red: 0, green: 0.475, blue: 0.757, alpha: 1) }
    class var secondaryBlue: UIColor { return #colorLiteral(red: 0, green: 0.368, blue: 0.584, alpha: 1) }
    class var backgroundGray: UIColor { return #colorLiteral(red: 0.973, green: 0.973, blue: 0.973, alpha: 1) }
    class var primaryTextColor: UIColor { return #colorLiteral(red: 0.196, green: 0.196, blue: 0.196, alpha: 1) }
    class var secondaryTextColor: UIColor { return #colorLiteral(red: 0.349, green: 0.349, blue: 0.349, alpha: 1) }
}

