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
    
    let nodesArray:[Node]
    
    private init(){
        let path = Bundle.main.path(forResource: "ContentPList", ofType: "plist")
        let content = NSArray(contentsOfFile: path!)
        nodesArray = NodeManager.populateNodesArray(content! as [AnyObject])
    }
    
    static func populateNodesArray(_ array:[AnyObject]) -> [Node] {
        var nodesArray = [Node]()
        for object in array {
            let dict = object as! [String:AnyObject]
            let node = Node(dict: dict)
            nodesArray.append(node)
        }
        return nodesArray
    }
    
    func nodesByDisplayNames(_ names:[String]) -> [Node] {
        var nodes = [Node]()
        for node in nodesArray {
            let children = node.children
            if let matchingNodes = children?.filter({ return names.contains($0.displayName) }) {
                nodes.append(contentsOf: matchingNodes)
            }
        }
        return nodes
    }
    
}

class Node: NSObject {
   
    var displayName:String = ""
    var descriptionText:String = ""
    var storyboardName:String?
    var children:[Node]? //if nil, then root node
    var dependency = [String]()
    
    init(dict:[String:AnyObject]){
        if let displayName = dict["displayName"] as? String {
            self.displayName = displayName
        }
        if let descriptionText = dict["descriptionText"] as? String {
            self.descriptionText = descriptionText
        }
        if let storyboardName = dict["storyboardName"] as? String {
            self.storyboardName = storyboardName
        }
        if let children = dict["children"] as? [AnyObject] {
            self.children = NodeManager.populateNodesArray(children)
        }
        if let dependency = dict["dependency"] as? [String] {
            self.dependency.append(contentsOf: dependency)
        }
    }

}
