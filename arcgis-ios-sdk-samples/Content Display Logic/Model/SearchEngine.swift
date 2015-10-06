//
//  SearchEngine.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 10/1/15.
//  Copyright © 2015 Esri. All rights reserved.
//

import UIKit

class SearchEngine: NSObject {

    static private let singleton = SearchEngine()
    
    private var indexArray:[String]!
    private var wordsDictionary:[String: [String]]!
    private var isLoading = false
    
    override init() {
        super.init()
        
        self.commonInit()
    }
    
    static func sharedInstance() -> SearchEngine {
        return singleton
    }
    
    private func commonInit() {
        if !self.isLoading {
            self.isLoading = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [weak self] () -> Void in
                guard let weakSelf = self else {
                    return
                }
                //get the directory URLs that contain readme files
                let readmeDirectoriesURLs = weakSelf.findReadmeDirectoriesURLs()
                //index the content of all the readme files
                weakSelf.indexAllReadmes(readmeDirectoriesURLs)
                self?.isLoading = false
            }
        }
    }
    
    private func findReadmeDirectoriesURLs() -> [NSURL] {
        
        var readmeDirectoriesURLs = [NSURL]()
        
        let fileManager = NSFileManager.defaultManager()
        let bundleURL = NSBundle.mainBundle().bundleURL
        
        //get all the directories from the bundle
        let directoryEnumerator = fileManager.enumeratorAtURL(bundleURL, includingPropertiesForKeys: [NSURLNameKey, NSURLIsDirectoryKey], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
        
        //check if the returned url is of a directory
        if let directoryEnumerator = directoryEnumerator {
            while let fileURL = directoryEnumerator.nextObject() as? NSURL {
                var isDirectory:AnyObject?
                do {
                    try fileURL.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                } catch {
                    print("throws")
                }
                //check if the directory contains a readme file
                if let isDirectory = isDirectory as? NSNumber where isDirectory.boolValue == true  {
                    let readmePath = "\(fileURL.path!)/README.md"
                    if fileManager.fileExistsAtPath(readmePath) {
                        readmeDirectoriesURLs.append(fileURL)
                    }
                }
            }
        }
        
        return readmeDirectoriesURLs
    }
    
    
    private func indexAllReadmes(readmeDirectoriesURLs:[NSURL]) {
        self.indexArray = [String]()
        self.wordsDictionary = [String: [String]]()
        
        let tagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeTokenType, NSLinguisticTagSchemeNameType, NSLinguisticTagSchemeLexicalClass], options: 0)
        
        autoreleasepool {
            for directoryURL in readmeDirectoriesURLs {
                
                if let contentString = self.contentOfReadmeFile(directoryURL.path!) {
                    
                    //sample display name
                    let sampleDisplayName = directoryURL.path!.componentsSeparatedByString("/").last!
                    
                    tagger.string = contentString
                    let range = NSMakeRange(0, contentString.characters.count)
                    var stop:ObjCBool?
                    tagger.enumerateTagsInRange(range, scheme: NSLinguisticTagSchemeLexicalClass, options: [NSLinguisticTaggerOptions.OmitWhitespace, NSLinguisticTaggerOptions.OmitPunctuation], usingBlock: { (tag:String, tokenRange:NSRange, sentenceRange:NSRange, stop) -> Void in
                        if tag == NSLinguisticTagNoun {
                            let word = (contentString as NSString).substringWithRange(tokenRange) as String
                            //trivial comparisons
                            if word != "`." && word != "```" && word != "`" {
                                var samples = self.wordsDictionary[word]
                                //if word already exists in the dictionary
                                if samples != nil {
                                    //add the sample display name to the list if not already present
                                    if !(samples!.contains(sampleDisplayName)) {
                                        samples!.append(sampleDisplayName)
                                        self.wordsDictionary[word] = samples
                                    }
                                }
                                else {
                                    samples = [sampleDisplayName]
                                    self.wordsDictionary[word] = samples
                                }
                                
                                //add to the index
                                if !self.indexArray.contains(word) {
                                    self.indexArray.append(word)
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    private func contentOfReadmeFile(directoryPath:String) -> String? {
        //find the path of the file
        let path = "\(directoryPath)/README.md"
        //read the content of the file
        if let content = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding) {
            return content
        }
        return nil
    }
    
    //MARK: - Public methods
    
    func searchForString(string:String) -> [String]? {
        
        //if the resources where released because of memory warnings
        if self.indexArray == nil {
            self.commonInit()
            return nil
        }
        
        //check if the string exists in the index array
        let words = self.indexArray.filter({ $0.uppercaseString == string.uppercaseString })
        if words.count > 0 {
            if let sampleDisplayNames = self.wordsDictionary[words[0]] {
                return sampleDisplayNames
            }
        }
        
        return nil
    }
    
    func suggestionsForString(string:String) -> [String]? {
        //if the resources where released because of memory warnings
        if self.indexArray == nil {
            self.commonInit()
            return nil
        }
        
        let suggestions = self.indexArray.filter( { $0.uppercaseString.rangeOfString(string.uppercaseString) != nil } )
        return suggestions
    }
}
