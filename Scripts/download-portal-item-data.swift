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

// This scripts downloads data for portal items. It takes three arguments. The
// first is a path to a plist file defining the portal items to download. The
// is a path to a plist file defining how various file types should be
// organized. The third is a path to the download directory.
//
// A mapping of item identifiers to relative paths is maintained inside the
// download directory. This mapping affords efficiently checking whether an
// item has already been downloaded.

import Foundation

protocol URLProvider {
    func makeURL(filename: String) -> URL
    func makeSubFolderURLForArchive(folderName: String) -> URL
}

struct DestinationURLProvider: URLProvider {
    let downloadDirectory: URL
    let fileTypes: [String: [String]]
    
    func makeURL(filename: String) -> URL {
        var url = downloadDirectory
        if let subdirectory = fileTypes.first(where: { $0.value.contains((filename as NSString).pathExtension) })?.key {
            url.appendPathComponent(subdirectory, isDirectory: true)
        }
        url.appendPathComponent(filename, isDirectory: false)
        return url
    }
    
    /// Make a sub-folder path for the extracted files from an archive.
    ///
    /// - Parameter folderName: The name of the folder.
    /// - Returns: A URL to the folder.
    func makeSubFolderURLForArchive(folderName: String) -> URL {
        var url = downloadDirectory
        if let subdirectory = fileTypes.first(where: { $0.value.contains("zip") })?.key {
            url.appendPathComponent(subdirectory, isDirectory: true)
        }
        url.appendPathComponent(folderName, isDirectory: true)
        return url
    }
}

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

/// Returns the name of the file in the ZIP archive at the given url.
///
/// - Parameter url: The url of a ZIP archive.
/// - Returns: The file name.
func nameOfFileInArchive(at url: URL) throws -> String {
    let outputPipe = Pipe()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo", isDirectory: false)
    process.arguments = ["-1", url.path]
    process.standardOutput = outputPipe
    try process.run()
    process.waitUntilExit()
    
    let filenameData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: filenameData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
}

func countFilesInArchive(at url: URL) throws -> Int {
    let outputPipe = Pipe()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo", isDirectory: false)
    process.arguments = ["-t", url.path]
    process.standardOutput = outputPipe
    try process.run()
    process.waitUntilExit()
    
    // The totals info looks like "240 files, 29461066 bytes uncompressed, 28292775 bytes compressed:  4.0%"
    let totalsInfo = outputPipe.fileHandleForReading.readDataToEndOfFile()
    // Extract the count from the info string
    let totalsCount = String(data: totalsInfo, encoding: .utf8)!.components(separatedBy: " ")[0]
    return Int(totalsCount)!
}

/// Uncompresses the data in the archive at the source URL into the destination URL.
///
/// - Parameters:
///   - sourceURL: The URL of a ZIP archive.
///   - destinationURL: The URL at which to uncompress the archive.
func uncompressArchive(at sourceURL: URL, to destinationURL: URL) throws {
    let outputPipe = Pipe()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip", isDirectory: false)
    // Unzip the archive into the specified sub-folder.
    process.arguments = [sourceURL.path, "-d", destinationURL.path]
    process.standardOutput = outputPipe
    
    try process.run()
    process.waitUntilExit()
    
    _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
    // print(String(data: unzipInfo, encoding: .utf8) ?? "No unzip output")
}

func downloadFile(at sourceURL: URL, destinationURLProvider: URLProvider, completion: @escaping (Result<URL, Error>) -> Void) {
    let downloadTask = URLSession.shared.downloadTask(with: sourceURL) { (temporaryURL, response, error) in
        if let temporaryURL = temporaryURL, let response = response {
            do {
                let suggestedFilename = response.suggestedFilename!
                let downloadURL: URL
                var extractURL: URL?
                let isArchive = (suggestedFilename as NSString).pathExtension == "zip"
                downloadURL = destinationURLProvider.makeURL(filename: suggestedFilename)
                if isArchive {
                    let fileCount = try countFilesInArchive(at: temporaryURL)
                    print("File count in the archive is \(fileCount)")
                    // Extract to a sub-folder with the same name as the archive without the extension.
                    extractURL = destinationURLProvider.makeSubFolderURLForArchive(folderName: (suggestedFilename as NSString).deletingPathExtension)
                }
                
                try FileManager.default.createDirectory(at: downloadURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                
                if FileManager.default.fileExists(atPath: downloadURL.path) {
                    try FileManager.default.removeItem(at: downloadURL)
                }
                
                if isArchive {
                    try uncompressArchive(at: temporaryURL, to: extractURL!)
                } else {
                    try FileManager.default.moveItem(at: temporaryURL, to: downloadURL)
                }
                
                completion(.success(downloadURL))
            } catch {
                completion(.failure(error))
            }
        } else if let error = error {
            completion(.failure(error))
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

guard arguments.count == 4 else {
    print("Invalid number of arguments")
    exit(1)
}

let portalItemsURL = URL(fileURLWithPath: arguments[1], isDirectory: false)
let fileTypesURL = URL(fileURLWithPath: arguments[2], isDirectory: false)
let downloadDirectoryURL = URL(fileURLWithPath: arguments[3], isDirectory: true)

if !FileManager.default.fileExists(atPath: downloadDirectoryURL.path) {
    do {
        try FileManager.default.createDirectory(at: downloadDirectoryURL, withIntermediateDirectories: false)
    } catch {
        print("Error creating download directory: \(error)")
        exit(1)
    }
}

let portalItems: [String: [PortalItem]] = {
    do {
        let data = try Data(contentsOf: portalItemsURL)
        return try PropertyListDecoder().decode([String: [PortalItem]].self, from: data)
    } catch {
        print("Error decoding portal items: \(error)")
        exit(1)
    }
}()

let fileTypes: [String: [String]] = {
    do {
        let data = try Data(contentsOf: fileTypesURL)
        return try PropertyListDecoder().decode([String: [String]].self, from: data)
    } catch {
        print("Error decoding file types: \(error)")
        exit(1)
    }
}()
let destinationURLProvider = DestinationURLProvider(downloadDirectory: downloadDirectoryURL, fileTypes: fileTypes)

typealias Identifier = String
typealias Filename = String
typealias DownloadedItems = [Identifier: Filename]

let downloadedItemsURL = downloadDirectoryURL.appendingPathComponent(".downloaded_items", isDirectory: false)
let previousDownloadedItems: DownloadedItems = {
    do {
        let data = try Data(contentsOf: downloadedItemsURL)
        let decoder = PropertyListDecoder()
        return try decoder.decode(DownloadedItems.self, from: data)
    } catch {
        return [:]
    }
}()
var downloadedItems = previousDownloadedItems

let dispatchGroup = DispatchGroup()

portalItems.forEach { (portalURLString, portalItems) in
    let portalURL = URL(string: portalURLString)!
    portalItems.forEach { (portalItem) in
        // Have we already downloaded the item?
        let filename = downloadedItems[portalItem.identifier] ?? portalItem.filename
        
        // Check if it is a non-archive single file.
        let isFileExist: Bool = FileManager.default.fileExists(atPath: destinationURLProvider.makeURL(filename: filename).path)
        
        // Check if there is a sub-folder for the corresponding archive, and the sub-folder is empty or not.
        // The corresponding sub-folder has the same name as the archive without the extension.
        let subFolderURL = destinationURLProvider.makeSubFolderURLForArchive(folderName: (filename as NSString).deletingPathExtension)
        let paths = try? FileManager.default.contentsOfDirectory(
            at: subFolderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        /// true: the folder exists and is empty;
        /// false: the folder exists and has content;
        /// nil: the folder does not exist or not accessible
        let isEmptySubFolder = paths?.isEmpty
        
        if isEmptySubFolder != nil && !isEmptySubFolder! {
            // One exception to this case is that the content in the folder is changed. There is no way to detect that
            // unless we keep track of each extracted file in the .downloaded_items dictionary.
            print("Item \(portalItem.identifier) has already been downloaded, and is extracted to an folder")
            downloadedItems[portalItem.identifier] = filename
        } else if isFileExist && isEmptySubFolder == nil {
            print("Item \(portalItem.identifier) has already been downloaded")
            // This is a temporary measure for users who currently don't have a downloaded items file.
            downloadedItems[portalItem.identifier] = filename
        } else {
            print("Downloading item \(portalItem.identifier)")
            fflush(stdout)
            
            dispatchGroup.enter()
            // Make an URL such as www.arcgis.com/sharing/rest/content/items/{itemIdentifier}/data
            let sourceURL = makeDataURL(portalURL: portalURL, itemIdentifier: portalItem.identifier)
            downloadFile(at: sourceURL, destinationURLProvider: destinationURLProvider) { (result) in
                switch result {
                case .success(let url):
                    // ' + 1' removes the leading path separator.
                    downloadedItems[portalItem.identifier] = url.lastPathComponent
                    dispatchGroup.leave()
                case .failure(let error):
                    print("Warning: Error downloading item \(portalItem.identifier): \(error)")
                    URLSession.shared.invalidateAndCancel()
                    exit(1)
                }
            }
        }
    }
}

dispatchGroup.wait()

// Update the downloaded items file if needed.
if downloadedItems != previousDownloadedItems {
    do {
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(downloadedItems)
        try data.write(to: downloadedItemsURL)
    } catch {
        print("Warning: Error recording downloaded items: \(error)")
        exit(1)
    }
}
