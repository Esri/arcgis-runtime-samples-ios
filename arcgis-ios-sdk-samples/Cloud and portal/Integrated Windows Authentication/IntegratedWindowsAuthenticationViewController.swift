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

/// A view controller that manages the interface of the Integrated Windows
/// Authentication sample.
class IntegratedWindowsAuthenticationViewController: UITableViewController {
    /// The text field for inputting the secure portal URL.
    @IBOutlet weak var securePortalURLTextField: UITextField!
    /// The cell that functions as the Search Secure button.
    @IBOutlet weak var searchSecureCell: UITableViewCell!
    
    /// The URL of the secure portal or `nil` if the user has not specified a
    /// valid URL.
    private var securePortalURL: URL? {
        didSet {
            guard securePortalURL != oldValue else { return }
            updateSearchSecureCellEnabledState()
        }
    }
    
    /// Updates the enabled state of the Search Secure cell. The cell is
    /// enabled if the user has specified a valid URL, otherwise it is disabled.
    func updateSearchSecureCellEnabledState() {
        searchSecureCell.isUserInteractionEnabled = securePortalURL != nil
    }
    
    // MARK: Portal Selection
    
    /// Called in response to the user tapping one of the Search cells.
    ///
    /// - Parameter portal: The portal selected by the user.
    func didSelectPortal(_ portal: AGSPortal) {
        let portalMapBrowserViewController = IntegratedWindowsAuthenticationPortalMapBrowserViewController(portal: portal)
        show(portalMapBrowserViewController, sender: self)
    }
    
    /// The object observing changes to the text of the secure portal URL text
    /// field.
    private var textDidChangeObserver: NSObjectProtocol!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "IntegratedWindowsAuthenticationViewController",
            "IntegratedWindowsAuthenticationSearchTableViewCell",
            "IntegratedWindowsAuthenticationPortalMapBrowserViewController",
            "IntegratedWindowsAuthenticationMapViewController"
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSearchSecureCellEnabledState()
        textDidChangeObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: securePortalURLTextField, queue: nil) { [unowned self](_) in
            self.securePortalURL = self.securePortalURLTextField.text.flatMap { URL(string: $0) }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let observer = textDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            textDidChangeObserver = nil
        }
    }
}

private extension IndexPath {
    /// The index path of the Search Public cell.
    static let searchPublic = IndexPath(row: 0, section: 0)
    /// The index path of the Search Secure cell.
    static let searchSecure = IndexPath(row: 1, section: 1)
}

extension IntegratedWindowsAuthenticationViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case .searchPublic:
            didSelectPortal(.arcGISOnline(withLoginRequired: false))
        case .searchSecure:
            let portal = AGSPortal(url: securePortalURL!, loginRequired: true)
            didSelectPortal(portal)
        default:
            break
        }
    }
}

extension IntegratedWindowsAuthenticationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let portal = AGSPortal(url: securePortalURL!, loginRequired: true)
        didSelectPortal(portal)
        return false
    }
}
