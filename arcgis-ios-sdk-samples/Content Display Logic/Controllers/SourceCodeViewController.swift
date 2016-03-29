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

class SourceCodeViewController: UIViewController, UIWebViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet private weak var webView:UIWebView!
    @IBOutlet private weak var toolbarTitleButton:UIBarButtonItem!
    
    private var listViewController:ListViewController!
    private var selectedFilenameIndex = 0
    var filenames:[String]!
    
    private var isListViewContainerVisible = false
    private var isListViewContainerAnimating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.delegate = self
        
        if self.filenames != nil && self.filenames.count > 0 {
            self.loadHTMLPage(self.filenames[0])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadHTMLPage(filename:String) {
        if let content = self.contentOfFile(filename) {
            self.setupToolbarTitle(filename, arrowPointingDown: true)
            let htmlString = self.htmlStringForContent(content)
            self.webView.loadHTMLString(htmlString, baseURL: NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath))
        }
    }
    
    func contentOfFile(name:String) -> String? {
        //find the path of the file
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: ".swift") {
            //read the content of the file
            if let content = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding) {
                return content
            }
        }
        return nil
    }
    
    func htmlStringForContent(content:String) -> String {
        let cssPath = NSBundle.mainBundle().pathForResource("xcode", ofType: "css") ?? ""
        let jsPath = NSBundle.mainBundle().pathForResource("highlight.pack", ofType: "js") ?? ""
        let scale  = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? "0.5" : "1.0"
        let stringForHTML = "<html> <head>" +
            "<meta name='viewport' content='width=device-width, initial-scale='\(scale)'/> " +
            "<link rel=\"stylesheet\" href=\"\(cssPath)\">" +
            "<script src=\"\(jsPath)\"></script>" +
            "<script>hljs.initHighlightingOnLoad();</script> </head> <body>" +
            "<pre><code class=\"Swift\"> \(content) </code></pre>" +
            "</body> </html>"
//        println(stringForHTML)
        // style=\"white-space:initial;\"
        return stringForHTML
    }
    
    func setupToolbarTitle(filename:String, arrowPointingDown:Bool) {

        var titleString = filename
        if self.filenames.count > 1 {
            titleString = String(format: "%@ %@", (arrowPointingDown ? "▶︎" : " \u{25B4}"), filename)
        }
        else {
            self.toolbarTitleButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.blackColor()], forState: UIControlState.Normal)
        }
        self.toolbarTitleButton.title = titleString
    }
    
    //MARK: - web view delegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
    //MARK: - Actions
    
    
    //MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if self.filenames.count > 1 {
            return true
        }
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FilenamesPopoverSegue" {
            let controller = segue.destinationViewController as! ListViewController
            controller.list = self.filenames
            controller.popoverPresentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            
            controller.setSelectAction({ [weak self] (index:Int) -> Void in
                if let weakSelf = self {
                    weakSelf.selectedFilenameIndex = index
                    let filename = weakSelf.filenames[index]
                    weakSelf.loadHTMLPage(filename)
                    weakSelf.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        }
    }
    
    //MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}
