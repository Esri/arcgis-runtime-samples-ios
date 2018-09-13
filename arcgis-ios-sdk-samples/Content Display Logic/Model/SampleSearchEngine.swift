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

class SampleSearchEngine {
    
    private var displayNamesByReadmeWords:[String: [String]] = [:]
    private var isLoadingReadmeIndex = false
    
    private let samples:[Sample]
    
    init(samples:[Sample]) {
        self.samples = samples
        
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
        for sample in samples{
            autoreleasepool {
                if let readmeURL = sample.readmeURL,
                    let readmeContent = try? String(contentsOf: readmeURL, encoding: .utf8) {
                    addToIndex(string:readmeContent, sampleDisplayName:sample.name)
                }
            }
        }
    }
    
    private func samplesWithReadmes(matching query:String) -> [Sample] {
        
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
        return samplesForDisplayNames(displayNamesForReadmeMatches)
    }
    
    private func samplesWithMetadata(matching query:String) -> [Sample] {
        
        // the normalized term to find
        let lowercasedQuery = query.lowercased()
        
        // all samples that match the term in their name or description
        var matchingSamples = samples.filter { (sample) -> Bool in
            return sample.name.lowercased().contains(lowercasedQuery) ||
                sample.description.lowercased().contains(lowercasedQuery)
        }
        // sort matches by relevance
        matchingSamples.sort { (sample1, sample2) -> Bool in
            // for convenience, store normalized names for re-use
            let sample1Name = sample1.name.lowercased()
            let sample2Name = sample2.name.lowercased()
            if let sample1Index = sample1Name.range(of: lowercasedQuery)?.lowerBound{
                if let sample2Index = sample2Name.range(of: lowercasedQuery)?.lowerBound{
                    // matches are both in the titles
                    if sample1Index != sample2Index{
                        // sort by index
                        return sample1Index < sample2Index
                    }
                    // indexes are the same, sort alphabetically
                    return sample1Name < sample2Name
                }
                else{
                    // only node1 has a title match, sort that first
                    return true
                }
            }
            else if sample2Name.contains(lowercasedQuery){
                // only node2 has a title match, sort that first
                return false
            }
            else{
                // matches are both in the descriptions
                
                // for convenience, store normalized descriptions for re-use
                let sample1Desc = sample1.description.lowercased()
                let sample2Desc = sample2.description.lowercased()
                let sample1Index = sample1Desc.range(of: lowercasedQuery)!.lowerBound
                let sample2Index = sample2Desc.range(of: lowercasedQuery)!.lowerBound
                if sample1Index != sample2Index{
                    // sort by index
                    return sample1Index < sample2Index
                }
                // indexes are the same, sort alphabetically
                return sample1Desc < sample2Desc
            }
        }
        return matchingSamples
    }
    
    private func samplesForDisplayNames(_ names:[String]) -> [Sample] {
        // preserve order
        return names.compactMap { (name) -> Sample? in
            return samples.first(where: { (sample) -> Bool in
                sample.name == name
            })
        }
    }
    
    //MARK: - Public methods
    
    func sortedSamples(matching query:String) -> [Sample] {
        
        // get nodes with titles or descriptions matching the query
        var matchingNodes = samplesWithMetadata(matching: query)
       
        // get nodes with readmes matching the query
        var nodesForReadmeMatches = Set(samplesWithReadmes(matching: query))
        
        // don't show duplicate results
        nodesForReadmeMatches.subtract(matchingNodes)
        
        // simply sort alphabetically
        let sortedNodesForReadmeMatches = nodesForReadmeMatches.sorted{ $0.name < $1.name }
        
        // readme matches are less likely to be releavant so append to the end of the name/description results
        matchingNodes.append(contentsOf: sortedNodesForReadmeMatches)
        
        return matchingNodes
    }

}
