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

class NodeManager {
    
    static let shared = NodeManager()
    
    let categoryNodes:[Node]
    var sampleNodes:[Node]{
        return categoryNodes.flatMap { (categoryNode) -> [Node] in
            return categoryNode.children ?? []
        }
    }
    
    private init(){
        let path = Bundle.main.path(forResource: "ContentPList", ofType: "plist")
        let contentArray = NSArray(contentsOfFile: path!)
        categoryNodes = NodeManager.nodes(from: contentArray as! [[String:AnyObject]])
    }
    
    static func nodes(from array:[[String:AnyObject]]) -> [Node] {
        return array.map { (dict) -> Node in
            return Node(dict: dict)
        }
    }
    
    func sampleNodesForDisplayNames(_ names:[String]) -> [Node] {
        // preserve order
        return names.compactMap { (name) -> Node? in
            return sampleNodes.first(where: { (node) -> Bool in
                node.displayName == name
            })
        }
    }
    
}

class Node: NSObject {
   
    var displayName:String = ""
    var descriptionText:String = ""
    var storyboardName:String?
    var children:[Node]? //if nil, then root node
    var dependency = [String]()
    var readmeURL:URL?
    
    init(dict:[String:AnyObject]){
        if let displayName = dict["displayName"] as? String {
            self.displayName = displayName
            readmeURL = Bundle.main.url(forResource: "README", withExtension: "md", subdirectory: displayName)
        }
        if let descriptionText = dict["descriptionText"] as? String {
            self.descriptionText = descriptionText
        }
        if let storyboardName = dict["storyboardName"] as? String {
            self.storyboardName = storyboardName
        }
        if let children = dict["children"] as? [[String:AnyObject]] {
            self.children = NodeManager.nodes(from: children)
        }
        if let dependency = dict["dependency"] as? [String] {
            self.dependency.append(contentsOf: dependency)
        }
    }

}
