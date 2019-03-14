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

/// A view controller for browsing maps in a portal.
class IntegratedWindowsAuthenticationPortalMapBrowserViewController: UITableViewController {
    /// The portal whose maps are displayed in the table view.
    let portal: AGSPortal
    
    /// Creates a portal map browser with the given portal.
    ///
    /// - Parameter portal: A portal.
    init(portal: AGSPortal) {
        self.portal = portal
        super.init(style: .grouped)
        portal.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.portalDidFailToLoad(with: error)
            } else {
                self.portalDidLoad()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The portal items to display in the table view.
    private var mapPortalItems = [AGSPortalItem]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    /// Called in response to the portal loading successfully.
    ///
    /// - Parameter portal: The portal that succeeded to load.
    func portalDidLoad() {
        title = portal.portalInfo?.portalName
        let parameters = AGSPortalQueryParameters(forItemsOf: .webMap, inGroup: nil)
        portal.findItems(with: parameters) { [weak self] (resultSet, error) in
            guard let self = self else { return }
            if let error = error {
                self.findDidFail(with: error)
            } else if let resultSet = resultSet {
                self.findDidSucceed(with: resultSet)
            }
        }
    }
    
    /// Called in response to the portal failing to load. Presents an alert
    /// announcing the failure.
    ///
    /// - Parameter error: The error that caused loading to fail.
    func portalDidFailToLoad(with error: Error) {
        state = .failed(error)
    }
    
    /// Called in response to the find operation completing successfully.
    ///
    /// - Parameter resultSet: The result set of the find operation.
    func findDidSucceed(with resultSet: AGSPortalQueryResultSet) {
        state = .loaded
        mapPortalItems = resultSet.results as? [AGSPortalItem] ?? []
    }
    
    /// Called in response to the find operation failing. Presents an alert
    /// announcing the failure.
    ///
    /// - Parameter error: The error that caused the find operation to fail.
    func findDidFail(with error: Error) {
        state = .failed(error)
    }
    
    /// Shows an activity indicator in the center of the table view.
    func showActivityIndicator() {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()
        
        let backgroundView = UIView()
        backgroundView.addSubview(activityIndicatorView)
        
        activityIndicatorView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        
        tableView.backgroundView = backgroundView
    }
    
    /// Hides the activity indicator.
    func hideActivityIndicator() {
        tableView.backgroundView = nil
    }
    
    /// Shows the given error in the center of the table view.
    ///
    /// - Parameter error: An error.
    func showError(_ error: Error) {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "Error:\n%@", error.localizedDescription)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let backgroundView = UIView()
        backgroundView.addSubview(label)
        
        label.leadingAnchor.constraint(equalTo: backgroundView.readableContentGuide.leadingAnchor).isActive = true
        backgroundView.readableContentGuide.trailingAnchor.constraint(equalTo: label.trailingAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        
        tableView.backgroundView = backgroundView
    }
    
    /// The possible states of the view controller.
    ///
    /// - loading: The view controller is currently loading the portal or portal
    /// items.
    /// - loaded: The view controller has loaded the portal and portal items.
    /// - failed: The view controller encountered an error loading either the
    /// portal or the portal items.
    enum State {
        case loading
        case loaded
        case failed(Error)
    }
    
    /// The state of the view controller. The default is `loading`.
    var state = State.loading {
        didSet {
            stateDidChange()
        }
    }
    
    /// Called in response to the view controller's state changing.
    func stateDidChange() {
        guard isViewLoaded else { return }
        switch state {
        case .loading:
            showActivityIndicator()
        case .loaded:
            hideActivityIndicator()
        case .failed(let error):
            showError(error)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        stateDidChange()
    }
}

extension IntegratedWindowsAuthenticationPortalMapBrowserViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return portal.loadStatus == .loaded ? 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapPortalItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = mapPortalItems[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Maps"
    }
}

extension IntegratedWindowsAuthenticationPortalMapBrowserViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let portalItem = mapPortalItems[indexPath.row]
        let map = AGSMap(item: portalItem)
        let mapViewController = IntegratedWindowsAuthenticationMapViewController(map: map)
        mapViewController.title = portalItem.title
        show(mapViewController, sender: nil)
    }
}
