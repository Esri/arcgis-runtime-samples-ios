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

class CustomWebViewController: UIViewController {

    @IBOutlet weak var webView:UIWebView!
    var reloadTimer:NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.userInteractionEnabled = false
        self.view.alpha = 0.9
        self.webView.scalesPageToFit = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Instance methods
    
    func loadUrlWithRepeatInterval(url:NSURL, withRepeatInterval interval:Int) {
        
        //invalidates the timer.
        if self.reloadTimer != nil {
            self.reloadTimer.invalidate()
            self.reloadTimer = nil
        }
        
        //loads the url
        self.webView.loadRequest(NSURLRequest(URL: url))
        
        //sets up the timer again for a refresh
        self.reloadTimer = NSTimer(timeInterval: 2, target: self, selector: "reload", userInfo: nil, repeats: true)
    }
    
    //MARK: - Helper Methods
    
    func reload() {
        //reloads the web view.
        self.webView.reload()
    }
}
