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

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Graphics Overlay
/// (Dictionary Renderer) 3D sample.
class GraphicsOverlayDictionaryRenderer3DViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = AGSScene(basemapType: .imagery)
            
            let graphicsOverlay = makeGraphicsOverlay()
            sceneView.graphicsOverlays.add(graphicsOverlay)
            sceneView.setViewpointCamera(AGSCamera(lookAt: graphicsOverlay.extent.center, distance: 15_000, heading: 0, pitch: 70, roll: 0))
        }
    }
    
    /// Creates a graphics overlay configured to display MIL-STD-2525D
    /// symbology.
    ///
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        
        let dictionarySymbolStyle = AGSDictionarySymbolStyle(specificationType: "mil2525d")
        graphicsOverlay.renderer = AGSDictionaryRenderer(dictionarySymbolStyle: dictionarySymbolStyle)
        
        // Read the messages and add a graphic to the overlay for each messages.
        if let messagesURL = Bundle.main.url(forResource: "Mil2525DMessages", withExtension: "xml") {
            do {
                let messagesData = try Data(contentsOf: messagesURL)
                let messages = try Mil2525DMessageParser().parseMessages(from: messagesData)
                let graphics = messages.map { AGSGraphic(geometry: AGSMultipoint(points: $0.points), symbol: nil, attributes: $0.attributes) }
                graphicsOverlay.graphics.addObjects(from: graphics)
            } catch {
                print("Error reading or decoding messages: \(error)")
            }
        } else {
            preconditionFailure("Missing Mil2525DMessages.xml")
        }
        
        return graphicsOverlay
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["GraphicsOverlayDictionaryRenderer3DViewController"]
    }
}

struct Mil2525DMessage {
    var points: [AGSPoint]
    var attributes: [String: Any]
}

class Mil2525DMessageParser: NSObject {
    struct ControlPoint {
        var x: Double
        var y: Double
    }
    
    private var controlPoints = [ControlPoint]()
    private var wkid: Int?
    private var attributes = [String: Any]()
    private var contentsOfCurrentElement = ""
    
    private var parsedMessages = [Mil2525DMessage]()
    
    func didFinishParsingMessage() {
        let spatialReference = AGSSpatialReference(wkid: wkid!)
        let points = controlPoints.map { AGSPoint(x: $0.x, y: $0.y, spatialReference: spatialReference) }
        let message = Mil2525DMessage(points: points, attributes: attributes)
        parsedMessages.append(message)
        
        wkid = nil
        controlPoints.removeAll()
        attributes.removeAll()
    }
    
    func parseMessages(from data: Data) throws -> [Mil2525DMessage] {
        defer { parsedMessages.removeAll() }
        let parser = XMLParser(data: data)
        parser.delegate = self
        let parsingSucceeded = parser.parse()
        if parsingSucceeded {
            return parsedMessages
        } else if let error = parser.parserError {
            throw error
        } else {
            return []
        }
    }
}

extension Mil2525DMessageParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        contentsOfCurrentElement.removeAll()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        contentsOfCurrentElement.append(contentsOf: string)
    }
    
    enum Element: String {
        case controlPoints = "_control_points"
        case message
        case messages
        case wkid = "_wkid"
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let element = Element(rawValue: elementName) {
            switch element {
            case .controlPoints:
                controlPoints = contentsOfCurrentElement.split(separator: ";").map { (pair) in
                    let coordinates = pair.split(separator: ",")
                    return ControlPoint(x: Double(coordinates.first!)!, y: Double(coordinates.last!)!)
                }
            case .message:
                didFinishParsingMessage()
            case .messages:
                break
            case .wkid:
                wkid = Int(contentsOfCurrentElement)
            }
        } else {
            attributes[elementName] = contentsOfCurrentElement
        }
        contentsOfCurrentElement.removeAll()
    }
}
