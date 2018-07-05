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

class BookmarksViewController: UIViewController, UIAlertViewDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var alertController:UIAlertController!
    
    private weak var bookmarksListVC:BookmarksListViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map using imagery with labels basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabels())
        
        //assign map to the mapView
        self.mapView.map = self.map

        //add default bookmarks
        self.addDefaultBookmarks()
        
        //zoom to the last bookmark
        self.map.initialViewpoint = (self.map.bookmarks.lastObject as AnyObject).viewpoint
        
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
        self.map.bookmarks.add(bookmark)
        
        //Strange Symbol
        viewpoint = AGSViewpoint(latitude: 37.401573, longitude: -116.867808, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Strange Symbol"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //Guitar-Shaped Forest
        viewpoint = AGSViewpoint(latitude: -33.867886, longitude: -63.985, scale: 4e4)
        bookmark = AGSBookmark()
        bookmark.name = "Guitar-Shaped Forest"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //Grand Prismatic Spring
        viewpoint = AGSViewpoint(latitude: 44.525049, longitude: -110.83819, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Grand Prismatic Spring"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
    }
    
    //MARK: - Actions
    
    @IBAction private func addAction() {
        //show an alert controller with textfield to get the name for the bookmark
        self.alertController = UIAlertController(title: "Provide the bookmark name", message: nil, preferredStyle: .alert)
        self.alertController.addTextField { (textField: UITextField) in
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self] (action: UIAlertAction) in
            guard let weakSelf = self else {
                return
            }
            //if the textfield is not empty then add a bookmark
            //else dont do anything
            let textField = weakSelf.alertController.textFields![0]
            if !textField.text!.isEmpty {
                weakSelf.addBookmark(withName: textField.text!)
            }
        }
        
        //add actions to alert controller
        self.alertController.addAction(cancelAction)
        self.alertController.addAction(doneAction)
        
        //present alert controller
        self.present(self.alertController, animated: true, completion: nil)
    }
    
    private func addBookmark(withName name:String) {
        //instantiate a bookmark and set the properties
        let bookmark = AGSBookmark()
        bookmark.name = name
        bookmark.viewpoint = self.mapView.currentViewpoint(with: AGSViewpointType.boundingGeometry)
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        //refresh the table view if it exists
        self.bookmarksListVC?.tableView.reloadData()
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PopoverSegue" {
            //get the destination view controller as BookmarksListViewController
            let controller = segue.destination as! BookmarksListViewController
            //store a weak reference in order to update the table view when adding new bookmark
            self.bookmarksListVC = controller
            //popover presentation logic
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            //assign the bookmarks to be shown
            controller.bookmarks = self.map.bookmarks as AnyObject as! [AGSBookmark]
            //set the closure to be executed when the user selects a bookmark
            controller.setSelectAction { [weak self] (viewpoint:AGSViewpoint) -> Void in
                self?.mapView.setViewpoint(viewpoint)
            }
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        //for popover or non modal presentation
        return UIModalPresentationStyle.none
    }
}
