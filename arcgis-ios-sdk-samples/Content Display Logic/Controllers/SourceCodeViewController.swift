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
import WebKit

class SourceCodeViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    /// The view to which the web view is added.
    @IBOutlet var contentView: UIView!
    /// The web view that displays the source code.
    @IBOutlet var webView: WKWebView!
    @IBOutlet var toolbarTitleButton: UIBarButtonItem! {
        didSet {
            if filenames.count <= 1 {
                if #available(iOS 13.0, *) {
                    toolbarTitleButton.tintColor = UIColor.label
                } else {
                    toolbarTitleButton.tintColor = UIColor.black
                }
            }
            toolbarTitleButton.possibleTitles = Set(filenames)
        }
    }
    
    private var listViewController: ListViewController!
    private var selectedFilenameIndex = 0
    var filenames = [String]()
    private var currentFilename: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let filename = currentFilename {
            loadHTMLPage(filename: filename)
        } else if let filename = filenames.first {
            currentFilename = filename
            loadHTMLPage(filename: filename)
        }
    }
    
    // Change the highlight.js rendered HTML when switch between modes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        loadHTMLPage(filename: currentFilename)
    }
    
    func loadHTMLPage(filename: String) {
        if let content = contentOfFile(filename) {
            setupToolbarTitle(filename, arrowPointingDown: true)
            let htmlString = htmlStringForContent(content)
            webView.loadHTMLString(htmlString, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
        }
    }
    
    func contentOfFile(_ name: String) -> String? {
        // find the path of the file
        if let path = Bundle.main.path(forResource: name, ofType: ".swift") {
            // read the content of the file
            if let content = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                return content
            }
        }
        return nil
    }
    
    func htmlStringForContent(_ content: String) -> String {
        let cssPath: String
        if traitCollection.userInterfaceStyle == .dark {
            cssPath = Bundle.main.path(forResource: "solarized-dark", ofType: "css")!
        } else {
            cssPath = Bundle.main.path(forResource: "xcode", ofType: "css")!
        }
        let jsPath = Bundle.main.path(forResource: "highlight.pack", ofType: "js")!
        let stringForHTML = """
            <html>
            <head>
                <meta name="viewport" content="initial-scale=1, width=device-width, height=device-height">
                <link rel="stylesheet" href="\(cssPath)">
                <script src="\(jsPath)"></script>
                <script>hljs.initHighlightingOnLoad();</script>
            </head>
            <body>
                <pre><code class="Swift">\(content)</code></pre>
            </body>
            </html>
            """
        return stringForHTML
    }
    
    func setupToolbarTitle(_ filename: String, arrowPointingDown: Bool) {
        let titleString: String
        if filenames.count > 1 {
            titleString = String(format: "%@ %@", (arrowPointingDown ? "▶︎" : " \u{25B4}"), filename)
        } else {
            titleString = filename
        }
        toolbarTitleButton.title = titleString
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return filenames.count > 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilenamesPopoverSegue" {
            let controller = segue.destination as! ListViewController
            controller.list = filenames
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            
            controller.setSelectAction { [weak self] (index: Int) in
                guard let self = self else { return }
                self.selectedFilenameIndex = index
                let filename = self.filenames[index]
                self.loadHTMLPage(filename: filename)
                self.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
