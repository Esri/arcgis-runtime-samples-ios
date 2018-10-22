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

class SampleInfoViewController: UIViewController {
    /// The web view that displays the readme.
    @IBOutlet private weak var webView: WKWebView!
    
    var readmeURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // We must construct the web view in code as long as we support iOS 10.
        // Prior to iOS 11, there was a bug in WKWebView.init(coder:) that
        // caused a crash.
        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        view.addSubview(webView)
        self.webView = webView
        
        if let readmeURL = readmeURL,
            let html = markdownTextFromFile(at: readmeURL) {
            displayHTML(html)
        }
    }
    
    func markdownTextFromFile(at url: URL) -> String? {

        //read the content of the file
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            //remove the images
            let pattern = "!\\[.*\\]\\(.*\\)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSMakeRange(0, content.count)
                return regex.stringByReplacingMatches(in: content, range: range, withTemplate: "")
            }
        }
        return nil
    }
    
    func displayHTML(_ readmeContent: String) {
        let cssPath = Bundle.main.path(forResource: "style", ofType: "css") ?? ""
        let string = """
            <!doctype html>
            <html>
            <head>
                <link rel="stylesheet" href="\(cssPath)">
                <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/foundation/5.5.2/css/foundation.min.css">
                <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
                <meta name="viewport" content="initial-scale=1, width=device-width, height=device-height">
            </head>
            <body>
                <div id="preview" sd-model-to-html="text">
                    <div id="content">\(readmeContent)</div>
                </div>
                <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/1.1.0/showdown.js"></script>
                <script>
                    var conv = new showdown.Converter();
                    var txt = document.getElementById('content').innerHTML;
                    document.getElementById('content').innerHTML = conv.makeHtml(txt);
                </script>
            </body>
            </html>
            """

        webView.loadHTMLString(string, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
    }
    
}

extension SampleInfoViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
}
