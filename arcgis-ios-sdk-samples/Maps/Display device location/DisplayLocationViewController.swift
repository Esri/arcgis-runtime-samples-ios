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

class DisplayLocationViewController: UIViewController, CustomContextSheetDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    private var sheet:CustomContextSheet!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        
        self.mapView.map = self.map
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayLocationViewController"]
        
        //setup the context sheet
        self.sheet = CustomContextSheet(images: ["LocationDisplayDisabledIcon", "LocationDisplayOffIcon", "LocationDisplayDefaultIcon", "LocationDisplayNavigationIcon2", "LocationDisplayHeadingIcon2"], highlightImages: nil, titles: ["Stop", "On", "Re-Center", "Navigation", "Compass"])
        self.sheet.translatesAutoresizingMaskIntoConstraints = false
        self.sheet.delegate = self
        self.view.addSubview(self.sheet)
        
        //add constraints
        let trailingConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: sheet, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 20)
        let bottomConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: sheet, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 20)
        self.view.addConstraints([trailingConstraint, bottomConstraint])
        
        //if the user pans the map in Navigation mode, the autoPanMode will automatically change to Off mode
        //in order to reflect those changes on the context sheet listen to the autoPanModeChangedHandler
        self.mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] (autoPanMode:AGSLocationDisplayAutoPanMode) in
            switch autoPanMode {
            case .off:
                self?.sheet.selectedIndex = 1
            case .recenter:
                self?.sheet.selectedIndex = 2
            case .navigation:
                self?.sheet.selectedIndex = 3
            case .compassNavigation:
                self?.sheet.selectedIndex = 4
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - CustomContextSheetDelegate
    
    //for selection on the context sheet
    //update the autoPanMode based on the selection
    func customContextSheet(_ customContextSheet: CustomContextSheet, didSelectItemAtIndex index: Int) {
        switch index {
        case 0:
            self.mapView.locationDisplay.stop()
        case 1:
            self.startLocationDisplay(with: AGSLocationDisplayAutoPanMode.off)
        case 2:
            self.startLocationDisplay(with: AGSLocationDisplayAutoPanMode.recenter)
        case 3:
            self.startLocationDisplay(with: AGSLocationDisplayAutoPanMode.navigation)
        default:
            self.startLocationDisplay(with: AGSLocationDisplayAutoPanMode.compassNavigation)
        }
    }
    
    //to start location display, the first time
    //dont forget to add the location request field in the info.plist file
    func startLocationDisplay(with autoPanMode:AGSLocationDisplayAutoPanMode) {
        self.mapView.locationDisplay.autoPanMode = autoPanMode
        self.mapView.locationDisplay.start { (error:Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                
                //update context sheet to Stop
                self.sheet.selectedIndex = 0
            }
        }
    }
}
