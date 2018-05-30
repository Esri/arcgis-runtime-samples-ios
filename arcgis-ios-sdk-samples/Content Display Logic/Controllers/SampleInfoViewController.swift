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

class SampleInfoViewController: UIViewController {
    
    @IBOutlet private weak var webView:UIWebView!
    
    var folderName:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.folderName != nil {
            self.fetchFileContent(for: self.folderName)
        }
    }
    
    func fetchFileContent(for folderName:String) {

        if let path = Bundle.main.path(forResource: "README", ofType: "md", inDirectory: folderName) {
            //read the content of the file
            if let content = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                //remove the images
                let pattern = "!\\[.*\\]\\(.*\\)"
                if let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) {
                    let newContent = regex.stringByReplacingMatches(in: content, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, content.count), withTemplate: "")
                    self.displayHTML(newContent)
                }
            }
        }
    }
    
    func displayHTML(_ readmeContent:String) {
        let cssPath = Bundle.main.path(forResource: "style", ofType: "css") ?? ""
        let string = "<!doctype html>" +
        "<html>" +
        "<head> <link rel=\"stylesheet\" href=\"\(cssPath)\">" +
        "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdnjs.cloudflare.com/ajax/libs/foundation/5.5.2/css/foundation.min.css\">" +
        "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css\">" +
        "<meta name=\"viewport\" content=\"initial-scale=1, width=device-width, height=device-height, viewport-fit=cover\">" +
        "</head>" +
        " <div id=\"preview\" sd-model-to-html=\"text\">" +
        "<div id=\"content\">" +
        "\(readmeContent)" +
        "</div></div>" +
        "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/showdown/1.1.0/showdown.js\"></script>" +
        "<script>" +
        "var conv = new showdown.Converter();" +
        "var txt = document.getElementById('content').innerHTML;" +
        "document.getElementById('content').innerHTML = conv.makeHtml(txt);" +
        "</script>" +
        "</body>" +
        "</html>"

        self.webView.loadHTMLString(string, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
