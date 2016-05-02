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

class BookmarksViewController: UIViewController, UIAlertViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var alert:UIAlertView!
    
    private weak var bookmarksListVC:BookmarksListViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map using imagery with labels basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabelsBasemap())
        
        //assign map to the mapView
        self.mapView.map = self.map

        //add default bookmarks
        self.addDefaultBookmarks()
        
        //zoom to the last bookmark
        self.map.initialViewpoint = self.map.bookmarks.last?.viewpoint
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["BookmarksViewController","BookmarksListViewController"]
    }
    
    private func addDefaultBookmarks() {
        //create a few bookmarks and add them to the map
        var viewpoint:AGSViewpoint, bookmark:AGSBookmark
        
        //Mysterious Desert Pattern
        viewpoint = AGSViewpoint(latitude: 27.3805833, longitude: 33.6321389, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Mysterious Desert Pattern"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.append(bookmark)
        
        //Strange Symbol
        viewpoint = AGSViewpoint(latitude: 37.401573, longitude: -116.867808, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Strange Symbol"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.append(bookmark)
        
        //Guitar-Shaped Forest
        viewpoint = AGSViewpoint(latitude: -33.867886, longitude: -63.985, scale: 4e4)
        bookmark = AGSBookmark()
        bookmark.name = "Guitar-Shaped Forest"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.append(bookmark)
        
        //Grand Prismatic Spring
        viewpoint = AGSViewpoint(latitude: 44.525049, longitude: -110.83819, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Grand Prismatic Spring"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.append(bookmark)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    @IBAction private func addAction() {
        //show an alert view with textfield to get the name for the bookmark
        self.alert = UIAlertView(title: "", message: "Provide the bookmark name", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Done")
        self.alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        self.alert.show()
    }
    
    private func addBookmark(name:String) {
        //instantiate a bookmark and set the properties
        let bookmark = AGSBookmark()
        bookmark.name = name
        bookmark.viewpoint = self.mapView.currentViewpointWithType(AGSViewpointType.BoundingGeometry)
        //add the bookmark to the map
        self.map.bookmarks.append(bookmark)
        //refresh the table view if it exists
        self.bookmarksListVC?.tableView.reloadData()
    }
    
    //MARK: - UIAlertView delegates
    
    func alertView(alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) {
        //if the user taps the done button
        //check if the textfield has some text
        //use the text as the bookmark name
        //otherwise do nothing
        if buttonIndex == 1 {
            if let text = alertView.textFieldAtIndex(0)?.text {
                self.addBookmark(text)
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PopoverSegue" {
            //get the destination view controller as BookmarksListViewController
            let controller = segue.destinationViewController as! BookmarksListViewController
            //store a weak reference in order to update the table view when adding new bookmark
            self.bookmarksListVC = controller
            //popover presentation logic
            controller.popoverPresentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            //assign the bookmarks to be shown
            controller.bookmarks = self.map.bookmarks
            //set the closure to be executed when the user selects a bookmark
            controller.setSelectAction({ [weak self] (viewpoint:AGSViewpoint) -> Void in
                self?.mapView.setViewpoint(viewpoint)
            })
        }
    }
    
    //MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        //for popover or non modal presentation
        return UIModalPresentationStyle.None
    }
}
