//
// Copyright © 2019 Esri.
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

/// The URL of the portal with which to authenticate.
private let portalURL = URL(string: "https://www.arcgis.com")!
/// The Client ID for an app registered with the server. The provided ID is for
/// a public app created by the ArcGIS Runtime team.
private let portalItemID = "e5039444ef3c48b8a8fdc9227f9be7c1"

/// The identifier with which this application was registered with the portal.
private let clientID = "lgAdHkYZYlwwfAhC"
/// The URL for redirecting after a successful authorization (this must be
/// configured in the Info plist).
private let redirectURLString = "my-ags-app://auth"

/// A view controller that manages the interface of the Authenticate with OAuth
/// sample.
class AuthenticateWithOAuthViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let portal = AGSPortal(url: portalURL, loginRequired: true)
        let portalItem = AGSPortalItem(portal: portal, itemID: portalItemID)
        return AGSMap(item: portalItem)
    }
    
    /// The OAuth configuration provided to the authentication manager.
    let oAuthConfiguration = AGSOAuthConfiguration(portalURL: portalURL, clientID: clientID, redirectURL: redirectURLString)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        AGSAuthenticationManager.shared().delegate = self
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oAuthConfiguration)
    }
    
    deinit {
        AGSAuthenticationManager.shared().oAuthConfigurations.remove(oAuthConfiguration)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "AuthenticateWithOAuthViewController"
        ]
    }
}

extension AuthenticateWithOAuthViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToShow viewController: UIViewController) {
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true)
    }
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToDismiss viewController: UIViewController) {
        dismiss(animated: true)
    }
}
