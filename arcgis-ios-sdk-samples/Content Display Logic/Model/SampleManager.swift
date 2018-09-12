//
//  SampleManager.swift
//  arcgis-ios-sdk-samples
//
//  Created by Quincy Morgan on 9/12/18.
//  Copyright © 2018 Esri. All rights reserved.
//

import Foundation

class SampleManager {
    
    static let shared = SampleManager()
    
    let categories:[Category]
    var samples:[Sample]{
        return categories.flatMap { $0.samples }
    }
    
    private init(){
        // Decode and populate Categories.
        categories = SampleManager.decodeCategories(at: SampleManager.contentPlistURL)
    }
    
    /// The URL of the content plist file inside the bundle.
    private static var contentPlistURL: URL {
        return Bundle.main.url(forResource: "ContentPList", withExtension: "plist")!
    }
    
    /// Decodes an array of categories from the plist at the given URL.
    ///
    /// - Parameter url: The url of a plist that defines categories.
    /// - Returns: An array of categories.
    private static func decodeCategories(at url: URL) -> [Category] {
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode([Category].self, from: data)
        } catch {
            fatalError("Error decoding categories at \(url): \(error)")
        }
    }
    
}
