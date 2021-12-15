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
import ArcGIS

class AppInfoViewController: UITableViewController {
    private let links = [
        Link(title: "Esri Community", url: URLs.esriCommunity),
        Link(title: "GitHub Repository", url: URLs.githubRepository),
        Link(title: "Sample Code", url: URLs.sampleCode)
    ]
    
    private let appInfos = [
        AppInfo(title: "App Version", detail: Strings.appMarketingVersionNumber),
        AppInfo(title: "SDK Version", detail: Strings.ArcGISSDKVersionString)
    ]
    
    @IBOutlet var appNameLabel: UILabel! {
        didSet {
            appNameLabel.text = Strings.appName
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate

extension AppInfoViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section.allCases[section].titleForHeader
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if Section.allCases[section] == .poweredBy {
            let currentYear = Calendar.current.component(.year, from: Date())
            return String(format: "Copyright © 2015-%d Esri. All Rights Reserved.", currentYear)
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if Section.allCases[section] == .poweredBy {
            return UITableView.automaticDimension
        } else {
            return .zero
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .appInfo:
            return appInfos.count
        case .links:
            return links.count
        case .poweredBy:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Section.allCases[indexPath.section].cellIdentifier, for: indexPath)
        switch Section.allCases[indexPath.section] {
        case .appInfo:
            cell.textLabel?.text = appInfos[indexPath.row].title
            cell.detailTextLabel?.text = appInfos[indexPath.row].detail
        case .links:
            cell.textLabel?.text = links[indexPath.row].title
        case .poweredBy:
            cell.textLabel?.text = "ArcGIS Runtime SDK for iOS"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section.allCases[indexPath.section] {
        case .links:
            UIApplication.shared.open(links[indexPath.row].url)
        case .poweredBy:
            UIApplication.shared.open(URLs.developers)
        default:
            return
        }
    }
}

// MARK: - Enums and Structs

private extension AppInfoViewController {
    struct AppInfo {
        let title: String
        let detail: String
    }
    
    struct Link {
        let title: String
        let url: URL
    }
    
    /// A convenience type for the table view sections.
    enum Section: Int, CaseIterable {
        case appInfo, links, poweredBy
        
        var titleForHeader: String {
            switch self {
            case .appInfo:
                return "App Info"
            case .links:
                return "Useful Links"
            case .poweredBy:
                return "Powered By"
            }
        }
        
        var cellIdentifier: String {
            switch self {
            case .appInfo:
                return "RightDetailCell"
            case .links:
                return "LinkCell"
            case .poweredBy:
                return "LinkCell"
            }
        }
    }
    
    enum Strings {
        /// The manually assigned marketing version, e.g. "100.13.0.1".
        static let appMarketingVersionNumber = "100.13.0.1"
        /// Name of this app bundle, i.e. "ArcGIS Runtime SDK Samples".
        static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        /// An end-user string representation of the ArcGIS Runtime SDK for iOS
        /// version shipped with the app, e.g. "100.13.0 (3355)".
        static let ArcGISSDKVersionString = String(format: "%@ (%@)", sdkVersionNumber, sdkBuildNumber)
        
        /// App version number, e.g. "100.13.0".
        private static let appVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        /// App build number, e.g. "20211214".
        private static let appbuildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
        /// SDK version number.
        private static let sdkVersionNumber = Bundle.agsBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        /// SDK build number.
        private static let sdkBuildNumber = Bundle.agsBundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
    
    enum URLs {
        static let developers = URL(string: "https://developers.arcgis.com/ios/")!
        static let esriCommunity = URL(string: "https://community.esri.com/t5/arcgis-runtime-sdk-for-ios-questions/bd-p/arcgis-runtime-sdk-for-ios-questions")!
        static let githubRepository = URL(string: "https://github.com/Esri/arcgis-runtime-samples-ios")!
        static let sampleCode = URL(string: "https://developers.arcgis.com/ios/swift/sample-code/")!
    }
}

private extension Bundle {
    static let agsBundle = AGSBundle()
}
