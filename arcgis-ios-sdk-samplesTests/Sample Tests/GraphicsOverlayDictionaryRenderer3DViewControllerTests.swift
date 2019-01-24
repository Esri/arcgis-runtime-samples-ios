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

import XCTest
import ArcGIS
@testable import ArcGIS_Runtime_SDK_Samples

class GraphicsOverlayDictionaryRenderer3DViewControllerTests: XCTestCase {
    func makeViewController() -> GraphicsOverlayDictionaryRenderer3DViewController {
        return UIStoryboard(name: "GraphicsOverlayDictionaryRenderer3D", bundle: nil).instantiateInitialViewController() as! GraphicsOverlayDictionaryRenderer3DViewController
    }
    
    func testLoadingView() {
        let viewController = makeViewController()
        
        viewController.loadViewIfNeeded()
        
        if let sceneView = viewController.sceneView {
            XCTAssertNotNil(sceneView.scene)
            XCTAssertEqual(sceneView.scene?.basemap?.name, AGSBasemap.imagery().name)
            XCTAssertEqual(sceneView.graphicsOverlays.count, 1)
            if let graphicsOverlay = sceneView.graphicsOverlays.firstObject as? AGSGraphicsOverlay {
                XCTAssertTrue(graphicsOverlay.renderer is AGSDictionaryRenderer)
                XCTAssertGreaterThan(graphicsOverlay.graphics.count, 0)
            }
        } else {
            XCTFail("sceneView is nil")
        }
    }
}

class MessageParserTests: XCTestCase {
    let messagesURL = Bundle.main.url(forResource: "Mil2525DMessages", withExtension: "xml")!
    
    func testParseMessagesAtURL() {
        let parser = MessageParser()
        do {
            let messagesData = try Data(contentsOf: messagesURL)
            let messages = try parser.parseMessages(from: messagesData)
            XCTAssertEqual(messages.count, 33)
            XCTAssertEqual(messages.first?.points.count, 36)
            XCTAssertEqual(messages.first?.attributes.count, 8)
        } catch {
            fatalError("Error parsing messages: \(error)")
        }
    }
}
