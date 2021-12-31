// Copyright 2021 Esri.
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

import SwiftUI
import ArcGIS

struct AppInfoView: View {
    private let links = [
        Link(title: "Esri Community", url: URLs.esriCommunity, subtitle: "Browse and discuss in the Esri Community"),
        Link(title: "GitHub Repository", url: URLs.githubRepository, subtitle: "Log an issue in the GitHub Repository"),
        Link(title: "API Reference", url: URLs.apiReference)
    ]
    
    private let appInfos = [
        AppInfo(title: "App Version", detail: Strings.appMarketingVersionNumber),
        AppInfo(title: "SDK Version", detail: Strings.ArcGISSDKVersionString)
    ]
    
    private let poweredBys = [
        Link(title: "ArcGIS Runtime Toolkit for iOS", url: URLs.toolkit),
        Link(title: "ArcGIS Runtime SDK for iOS", url: URLs.developers)
    ]
    
    private let copyrightFooter: String = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return String(format: "Copyright © 2015-%d Esri. All Rights Reserved.", currentYear)
    }()
    
    private func header(for link: Link) -> String? {
        if link == links.first {
            return "Useful Links"
        } else {
            return nil
        }
    }
    
    var body: some View {
        List {
            HStack {
                Spacer()
                VStack {
                    Image("AppIcon2", bundle: .main)
                    Text(Strings.appName)
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
            // App info section.
            Section(header: Text("App Info")) {
                ForEach(appInfos) { appInfo in
                    HStack {
                        Text(appInfo.title)
                        Spacer()
                        Text(appInfo.detail)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            // Useful links section.
            ForEach(links) { link in
                if let footer = link.subtitle {
                    if let header = header(for: link) {
                        Section(header: Text(header), footer: Text(footer)) {
                            LinkRow(link: link)
                        }
                    } else {
                        Section(footer: Text(footer)) {
                            LinkRow(link: link)
                        }
                    }
                } else {
                    Section {
                        LinkRow(link: link)
                    }
                }
            }
            // Powered-by links section.
            Section(header: Text("Powered By"), footer: Text(copyrightFooter)) {
                ForEach(poweredBys) { link in
                    LinkRow(link: link)
                }
            }
        }
    }
}

private extension AppInfoView {
    struct LinkRow: View {
        let link: Link
        
        var body: some View {
            Button(action: {
                UIApplication.shared.open(link.url)
            }, label: {
                Text(link.title)
            })
        }
    }
    
    struct AppInfo: Identifiable {
        let title: String
        let detail: String
        
        var id: String { title }
    }
    
    struct Link: Equatable, Identifiable {
        let title: String
        let url: URL
        let subtitle: String?
        
        var id: String { title }
        
        init(title: String, url: URL, subtitle: String? = nil) {
            self.title = title
            self.url = url
            self.subtitle = subtitle
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
        /// App version string representation for internal usage.
        static let appInternalVersionString = String(format: "%@ (%@)", appVersionNumber, appbuildNumber)
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
        static let toolkit = URL(string: "https://github.com/Esri/arcgis-runtime-toolkit-ios")!
        static let apiReference = URL(string: "https://developers.arcgis.com/ios/api-reference/")!
    }
}

private extension Bundle {
    static let agsBundle = AGSBundle()
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
    }
}
