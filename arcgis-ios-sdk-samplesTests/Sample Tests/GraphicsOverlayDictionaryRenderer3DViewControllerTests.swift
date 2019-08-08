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
                XCTAssertGreaterThan(graphicsOverlay.graphics.count, 0)
            }
        } else {
            XCTFail("sceneView is nil")
        }
    }
}

class MessageParserTests: XCTestCase {
    func testParseMessagesAtURL() {
        let messagesURL = Bundle.main.url(forResource: "Mil2525DMessages", withExtension: "xml")!
        
        guard let messagesData = try? Data(contentsOf: messagesURL) else {
            XCTFail("Error loading data from URL + \(messagesURL)")
            return
        }
        
        let messages: [Message]
        do {
            let parser = MessageParser()
            messages = try parser.parseMessages(from: messagesData)
        } catch {
            XCTFail("Error parsing messages: \(error)")
            return
        }
        
        let expectedMessageCount = 33
        let actualMessageCount = messages.count
        XCTAssertEqual(actualMessageCount, expectedMessageCount)

        let firstMessage = messages.first
        XCTAssertNotNil(firstMessage)
        
        let expectedPointCount = 36
        let actualFirstMessagePointCount = firstMessage?.points.count ?? 0
        XCTAssertEqual(actualFirstMessagePointCount, expectedPointCount)

        let expectedMinimumAttributeCount = 7
        let actualFirstMessageAttributeCount = firstMessage?.attributes.count ?? 0
        XCTAssertGreaterThanOrEqual(actualFirstMessageAttributeCount, expectedMinimumAttributeCount)
    }
}
