//
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
//

import UIKit
import ArcGIS

class SearchForWebmapByKeywordViewController: UIViewController, WebMapsCollectionViewControllerDelegate, UISearchBarDelegate {

    @IBOutlet var searchBar:UISearchBar!
    @IBOutlet var button:UIButton!
    
    private var portal:AGSPortal!
    private var portalItems:[AGSPortalItem]!
    private var webMapsCollectionVC:WebMapsCollectionViewController!
    private var selectedWebMap:AGSPortalItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // create the portal
        self.portal = AGSPortal(url: URL(string: "https://arcgis.com")!, loginRequired: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(unhideButton), name: UIResponder.keyboardDidShowNotification, object: nil)
    
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SearchForWebmapByKeywordViewController", "WebMapCell", "WebMapsCollectionViewController", "WebMapViewController"]
    }
 
    func searchForWebMap(_ keyword:String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // webmaps authored prior to July 2nd, 2014 are not supported - so search only from that date to the current time
        let date1 = dateFormatter.date(from: "July 2, 2014")!
        let dateString = "uploaded:[000000\(Int(date1.timeIntervalSince1970)) TO 000000\(Int(Date().timeIntervalSince1970))]"
        
        // create query parameters looking for items of type .webMap and
        // with our keyword and date string
        let queryParams = AGSPortalQueryParameters(forItemsOf: .webMap, withSearch: "\(keyword) AND \(dateString)")
        self.portal.findItems(with: queryParams) { [weak self] (resultSet: AGSPortalQueryResultSet?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                //if our results are an array of portal items, set it on our web maps collection ViewController
                if let portalItems = resultSet?.results as? [AGSPortalItem] {
                    self?.webMapsCollectionVC.portalItems = portalItems
                }
            }
        }
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, !text.isEmpty {
            //we have text, search for web maps
            self.searchForWebMap(text)
        }
        
        //hide keyboard
        self.buttonAction()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            //reset collection view
            self.webMapsCollectionVC.portalItems = nil
        }
    }
    
    //MARK: - Actions
    
    @IBAction func buttonAction() {
        self.button.isHidden = true
        self.searchBar.resignFirstResponder()
    }
    
    @objc func unhideButton() {
        self.button.isHidden = false
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WebMapsCollectionSegue" {
            if let webMapsCollectionVC = segue.destination as? WebMapsCollectionViewController {
                self.webMapsCollectionVC = webMapsCollectionVC
                self.webMapsCollectionVC.delegate = self
            }
        }
        else if segue.identifier == "WebMapVCSegue" {
            let controller = segue.destination as! WebMapViewController
            controller.portalItem = self.selectedWebMap
        }
    }
    
    //MARK: - WebMapsCollectionVCDelegate
    
    func webMapsCollectionVC(_ webMapsCollectionVC: WebMapsCollectionViewController, didSelectWebMap webMap: AGSPortalItem) {
        // save selected web map
        self.selectedWebMap = webMap
        //show web map
        self.performSegue(withIdentifier: "WebMapVCSegue", sender: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
