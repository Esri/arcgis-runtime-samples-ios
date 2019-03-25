//
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

protocol TilePackagesListViewControllerDelegate: AnyObject {
    func tilePackagesListViewController(_ tilePackagesListViewController: TilePackagesListViewController, didSelectTilePackageAt url: URL)
}

class TilePackagesListViewController: UITableViewController {
    weak var delegate: TilePackagesListViewControllerDelegate?
    
    private var bundleTilePackageURLs = [URL]()
    private var documentTilePacakgeURLs = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fetch tile packages from bundle and document directory
        self.fetchTilePackages()
    }
    
    func fetchTilePackages() {
        // Fetch URLs for tile packages in the main bundle.
        if let urls = Bundle.main.urls(forResourcesWithExtension: "tpk", subdirectory: nil) {
            bundleTilePackageURLs = urls
        }
        
        // Fetch URLs for tile packages in the documents directory.
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let subpaths = FileManager.default.subpaths(atPath: documentDirectoryURL.path) {
            let predicate = NSPredicate(format: "SELF MATCHES %@", ".*tpkx?$")
            documentTilePacakgeURLs = subpaths.lazy
                .filter { predicate.evaluate(with: $0) }
                .map { documentDirectoryURL.appendingPathComponent($0) }
        }
    }
    
    /// A section in the table view.
    ///
    /// - bundle: The section showing tile packages in the bundle.
    /// - documentsDirectory: The section showing tile packages in the documents
    /// directory.
    enum Section: CaseIterable {
        case bundle
        case documentsDirectory
    }
    
    /// Returns the `URL` corresponding to the row at the given index path.
    ///
    /// - Parameter indexPath: An index path.
    /// - Returns: A `URL`.
    func urlForRow(at indexPath: IndexPath) -> URL {
        switch Section.allCases[indexPath.section] {
        case .bundle:
            return bundleTilePackageURLs[indexPath.row]
        case .documentsDirectory:
            return documentTilePacakgeURLs[indexPath.row]
        }
    }
}

extension TilePackagesListViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .bundle:
            return bundleTilePackageURLs.count
        case .documentsDirectory:
            return documentTilePacakgeURLs.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TilePackageCell", for: indexPath)
        cell.textLabel?.text = urlForRow(at: indexPath).lastPathComponent
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.allCases[section] {
        case .bundle:
            return "From the bundle"
        case .documentsDirectory:
            return "From the documents directory"
        }
    }
}

extension TilePackagesListViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = urlForRow(at: indexPath)
        delegate?.tilePackagesListViewController(self, didSelectTilePackageAt: url)
    }
}
