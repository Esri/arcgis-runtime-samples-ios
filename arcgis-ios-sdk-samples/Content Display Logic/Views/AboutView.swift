// Copyright 2022 Esri.
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

struct AboutView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var copyrightText: Text {
        if #available(iOS 15.0, *) {
            return Text("Copyright © 2015-\(Date(), format: .dateTime.year()) Esri. All Rights Reserved.")
        } else {
            let currentYear = Calendar.current.component(.year, from: Date())
            return Text("Copyright © 2015-\(currentYear) Esri. All Rights Reserved.")
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack {
                        Image("AppIcon2", label: Text("App icon"))
                        Text(Bundle.main.name)
                            .font(.headline)
                        copyrightText
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
                }
                Section {
                    VersionRow(title: "Version", version: Bundle.main.shortVersion)
                    VersionRow(title: "SDK Version", version: Bundle.arcGIS.shortVersion, build: Bundle.arcGIS.version)
                }
                Section(header: Text("Powered By")) {
                    Link("ArcGIS Runtime Toolkit for iOS", destination: .toolkit)
                    Link("ArcGIS Runtime SDK for iOS", destination: .developers)
                }
                Section(footer: Text("Browse and discuss in the Esri Community.")) {
                    Link("Esri Community", destination: .esriCommunity)
                }
                Section(footer: Text("Log an issue in the GitHub repository.")) {
                    Link("GitHub Repository", destination: .githubRepository)
                }
                Section(footer: Text("View details about the API.")) {
                    Link("API Reference", destination: .apiReference)
                }
            }
            .navigationBarTitle("About", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                        .foregroundColor(.white)
                        .bold()
                })
            )
        }
        .navigationViewStyle(.stack)
    }
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

private struct VersionRow: View {
    let title: String
    let version: String
    let build: String
    
    init(title: String, version: String, build: String = "") {
        self.title = title
        self.version = version
        self.build = build
    }
    
    var versionText: Text {
        if !build.isEmpty {
            return Text("\(version) (\(build))")
        } else {
            return Text("\(version)")
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            versionText
                .foregroundColor(.secondary)
        }
    }
}

private extension Bundle {
    static let arcGIS = Bundle(identifier: "com.esri.arcgis.runtime.ios")!
    
    var name: String { object(forInfoDictionaryKey: "CFBundleName") as? String ?? "" }
    var shortVersion: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var version: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }
}

private extension URL {
    static let developers = URL(string: "https://developers.arcgis.com/ios/")!
    static let esriCommunity = URL(string: "https://community.esri.com/t5/arcgis-runtime-sdk-for-ios-questions/bd-p/arcgis-runtime-sdk-for-ios-questions")!
    static let githubRepository = URL(string: "https://github.com/Esri/arcgis-runtime-samples-ios")!
    static let toolkit = URL(string: "https://github.com/Esri/arcgis-runtime-toolkit-ios")!
    static let apiReference = URL(string: "https://developers.arcgis.com/ios/api-reference/")!
}
