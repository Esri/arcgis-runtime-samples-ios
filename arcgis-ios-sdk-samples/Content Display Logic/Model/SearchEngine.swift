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

class SearchEngine {

    static let shared = SearchEngine()
    
    private var displayNamesByReadmeWords:[String: [String]] = [:]
    private var isLoadingReadmeIndex = false
    
    private init() {
        if !isLoadingReadmeIndex {
            isLoadingReadmeIndex = true
            DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                guard let strongSelf = self else {
                    return
                }

                //index the content of all sample names, descriptions, and readme files
                strongSelf.indexSampleReadmes()
                strongSelf.isLoadingReadmeIndex = false
            }
        }
    }

    private func indexSampleReadmes() {
        displayNamesByReadmeWords = [:]
        
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .nameType, .lexicalClass], options: 0)
        
        func addToIndex(string:String,sampleDisplayName:String){
            
            tagger.string = string
            let range = NSMakeRange(0, string.count)
            tagger.enumerateTags(in: range,
                                 scheme: NSLinguisticTagScheme.lexicalClass,
                                 options: [.omitWhitespace, .omitPunctuation],
                                 using: { (tag:NSLinguisticTag?, tokenRange:NSRange, sentenceRange:NSRange, _) -> Void in
                
                guard let tag = tag else {
                    return
                }
               
                if  [NSLinguisticTag.noun,.verb,.adjective,.otherWord].contains(tag) {
                    let word = ((string as NSString).substring(with: tokenRange) as String).lowercased()
                    
                    //trivial comparisons
                    if word != "`." && word != "```" && word != "`" {
                        //if word already exists in the dictionary
                        if var samples = displayNamesByReadmeWords[word] {
                            //add the sample display name to the list if not already present
                            if !samples.contains(sampleDisplayName) {
                                samples.append(sampleDisplayName)
                                displayNamesByReadmeWords[word] = samples
                            }
                        }
                        else {
                            displayNamesByReadmeWords[word] = [sampleDisplayName]
                        }
                    }
                }
            })
        }
        
        // index all nodes
        for node in NodeManager.shared.sampleNodes{
            autoreleasepool {
                if let readmeURL = node.readmeURL,
                    let readmeContent = try? String(contentsOf: readmeURL, encoding: .utf8) {
                    addToIndex(string:readmeContent, sampleDisplayName:node.displayName)
                }
            }
        }
    }
    
    private func samplesWithReadmes(matching query:String) -> [Node] {
        
        // skip readmes if not yet loaded
        guard !isLoadingReadmeIndex else{
            return []
        }
        
        // the normalized term to find
        let lowercasedQuery = query.lowercased()
        
        // search readmes, limited to matching a single word
        let displayNamesForReadmeMatches = displayNamesByReadmeWords.keys.flatMap { (readmeWord) -> [String] in
            if readmeWord.contains(lowercasedQuery){
                return displayNamesByReadmeWords[readmeWord] ?? []
            }
            return []
        }
        return NodeManager.shared.sampleNodesForDisplayNames(displayNamesForReadmeMatches)
    }
    
    private func samplesWithMetadata(matching query:String) -> [Node] {
        
        // the normalized term to find
        let lowercasedQuery = query.lowercased()
        
        // all samples that match the term in their name or description
        var matchingNodes = NodeManager.shared.sampleNodes.filter { (node) -> Bool in
            return node.displayName.lowercased().contains(lowercasedQuery) ||
                node.descriptionText.lowercased().contains(lowercasedQuery)
        }
        // sort matches by relevance
        matchingNodes.sort { (node1, node2) -> Bool in
            // for convenience, store normalized names for re-use
            let node1Name = node1.displayName.lowercased()
            let node2Name = node2.displayName.lowercased()
            if let node1Index = node1Name.range(of: lowercasedQuery)?.lowerBound{
                if let node2Index = node2Name.range(of: lowercasedQuery)?.lowerBound{
                    // matches are both in the titles
                    if node1Index != node2Index{
                        // sort by index
                        return node1Index < node2Index
                    }
                    // indexes are the same, sort alphabetically
                    return node1Name < node2Name
                }
                else{
                    // only node1 has a title match, sort that first
                    return true
                }
            }
            else if node2Name.contains(lowercasedQuery){
                // only node2 has a title match, sort that first
                return false
            }
            else{
                // matches are both in the descriptions
                
                // for convenience, store normalized descriptions for re-use
                let node1Desc = node1.descriptionText.lowercased()
                let node2Desc = node2.descriptionText.lowercased()
                let node1Index = node1Desc.range(of: lowercasedQuery)!.lowerBound
                let node2Index = node2Desc.range(of: lowercasedQuery)!.lowerBound
                if node1Index != node2Index{
                    // sort by index
                    return node1Index < node2Index
                }
                // indexes are the same, sort alphabetically
                return node1Desc < node2Desc
            }
        }
        return matchingNodes
    }
    
    //MARK: - Public methods
    
    func sortedSamples(matching query:String) -> [Node] {
        
        // get nodes with titles or descriptions matching the query
        var matchingNodes = samplesWithMetadata(matching: query)
       
        // get nodes with readmes matching the query
        var nodesForReadmeMatches = Set(samplesWithReadmes(matching: query))
        
        // don't show duplicate results
        nodesForReadmeMatches.subtract(matchingNodes)
        
        // simply sort alphabetically
        let sortedNodesForReadmeMatches = nodesForReadmeMatches.sorted{ $0.displayName < $1.displayName }
        
        // readme matches are less likely to be releavant so append to the end of the name/description results
        matchingNodes.append(contentsOf: sortedNodesForReadmeMatches)
        
        return matchingNodes
    }

}
