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

// This scripts downloads data for portal items. It takes two arguments. The
// first is a path to a plist file defining the portal items to download. The
// second is a path to the download directory.

import Foundation

/// Creates a URL for the given item in the given portal.
///
/// - Parameters:
///   - itemIdentifier: The identifier of the item.
///   - portalURL: The URL of the portal.
/// - Returns: A new URL.
func makeDataURL(portalURL: URL, itemIdentifier: String) -> URL {
    return portalURL
        .appendingPathComponent("sharing")
        .appendingPathComponent("rest")
        .appendingPathComponent("content")
        .appendingPathComponent("items")
        .appendingPathComponent(itemIdentifier)
        .appendingPathComponent("data")
}

/// Creates a URL for a file with the given filename in the given directory.
///
/// - Parameters:
///   - downloadDirectoryURL: The directory in which the file will be
///   downloaded.
///   - filename: The name of the downloaded file.
/// - Returns: A new URL.
func makeDownloadURL(downloadDirectoryURL: URL, filename: String) -> URL {
    let subdirectories = [
        "slpk": "Scene Layer Packages",
        "mspk": "Mobile Scene Packages",
        "tpk": "Tile Packages"
    ]
    var downloadURL = downloadDirectoryURL
    if let subdirectory = subdirectories[(filename as NSString).pathExtension] {
        downloadURL.appendPathComponent(subdirectory)
    }
    downloadURL.appendPathComponent(filename)
    return downloadURL
}

extension FileManager {
    /// Indicates whether a file or directory exists at the given URL.
    ///
    /// - Parameter url: A URL.
    /// - Returns: `true` if a file or directory at the given path exists,
    /// otherwise `false`.
    func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }
}

/// Downloads the file at the given URL to the given URL.
///
/// - Parameters:
///   - sourceURL: The URL of the file to download.
///   - destinationURL: The URL to which the file should be downloaded.
func downloadFile(at sourceURL: URL, to destinationURL: URL, completion: @escaping (Error?) -> Void) {
    let downloadTask = URLSession.shared.downloadTask(with: sourceURL) { (urlOrNil, responseOrNil, errorOrNil) in
        if let fileURL = urlOrNil {
            do {
                try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: fileURL, to: destinationURL)
                completion(nil)
            } catch {
                completion(error)
            }
        } else if let error = errorOrNil {
            completion(error)
        }
    }
    downloadTask.resume()
}

/// A type that describes an item in a portal.
struct PortalItem: Decodable {
    /// The identifier of the item.
    var identifier: String
    /// The filename of the item.
    var filename: String
}

let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    print("Invalid number of arguments")
    exit(1)
}

let portalItemsURL = URL(fileURLWithPath: arguments[1], isDirectory: false)
let downloadDirectoryURL = URL(fileURLWithPath: arguments[2], isDirectory: true)

let portalItems: [String: [PortalItem]]

do {
    let data = try Data(contentsOf: portalItemsURL)
    portalItems = try PropertyListDecoder().decode([String: [PortalItem]].self, from: data)
} catch {
    print("Error decoding portal items: \(error)")
    exit(1)
}

let dispatchGroup = DispatchGroup()

portalItems.forEach { (portalURLString, portalItems) in
    let portalURL = URL(string: portalURLString)!
    portalItems.forEach { (portalItem) in
        let destinationURL = makeDownloadURL(downloadDirectoryURL: downloadDirectoryURL, filename: portalItem.filename)
        guard !FileManager.default.fileExists(at: destinationURL) else {
            return
        }
        
        dispatchGroup.enter()
        
        print("Downloading \(portalItem.filename)")
        fflush(stdout)
        let sourceURL = makeDataURL(portalURL: portalURL, itemIdentifier: portalItem.identifier)
        downloadFile(at: sourceURL, to: destinationURL) { (error) in
            if let error = error {
                print("Error downloading \(portalItem.filename): \(error)")
                URLSession.shared.invalidateAndCancel()
                exit(1)
            } else {
                dispatchGroup.leave()
            }
        }
    }
}

dispatchGroup.wait()
