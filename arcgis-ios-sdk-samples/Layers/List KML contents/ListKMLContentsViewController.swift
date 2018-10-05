// Copyright 2018 Esri.
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
import ArcGIS

class ListKMLContentsViewController: UITableViewController {
    
    private var kmlDataset: AGSKMLDataset?
    
    /// The full node tree flattened to an array of tuples that include each node's level.
    /// Used as the model for the table view.
    private var flattenedNodes: [(node: AGSKMLNode, level: Int)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard self.kmlDataset == nil else {
            return
        }
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListKMLContentsViewController", "ListKMLContentsSceneViewController"]
        
        // create the dataset from the local kml/kmz file with the given name
        let kmlDataset = AGSKMLDataset(name: "esri_test_data")
        self.kmlDataset = kmlDataset
        
        // load the dataset asynchronously so we can list its contents
        kmlDataset.load {[weak self] (error) in
            
            guard let self = self else{
                return
            }
            
            guard error == nil else{
                // display the error as an alert
                let alertController = UIAlertController(title: error?.localizedDescription, message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            self.flattenedNodes = []
            func addNodes(_ nodes: [AGSKMLNode], level: Int){
                for node in nodes{
                    node.isVisible = true
                    self.flattenedNodes.append((node, level))
                    addNodes(self.childNodes(of: node), level: level+1)
                }
            }
            addNodes(kmlDataset.rootNodes, level: 0)
            
            // populate the outline view now that the data is loaded
            self.tableView.reloadData()
        }
    }
    
    /// Returns all the child nodes of this node.
    private func childNodes(of node: AGSKMLNode) -> [AGSKMLNode] {
        if let container = node as? AGSKMLContainer {
            return container.childNodes
        }
        else if let networkLink = node as? AGSKMLNetworkLink {
            return networkLink.childNodes
        }
        return []
    }
    
    //MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flattenedNodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // get and setup a cell to display the node info
        let cell = tableView.dequeueReusableCell(withIdentifier: "NodeCell")!
        let flattenedNodeInfo = flattenedNodes[indexPath.row]
        let node = flattenedNodeInfo.node
        cell.textLabel?.text = node.name
        cell.detailTextLabel?.text = "\(type(of:node))"
        // set the indentation based on the node hierarchy
        cell.indentationLevel = flattenedNodeInfo.level
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else{
            return
        }
        let node = flattenedNodes[indexPath.row].node
        // create and show a view controller showing the scene and the extent of this node
        let viewController = storyboard?.instantiateViewController(withIdentifier: "ListKMLContentsSceneViewController") as! ListKMLContentsSceneViewController
        viewController.kmlDataset = kmlDataset
        viewController.node = node
        show(viewController, sender: self)
    }
    
}
