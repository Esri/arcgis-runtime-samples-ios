//
// Copyright © 2018 Esri.
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

class Calculate3DDistanceViewControllerTests: XCTestCase {
    func makeViewController() -> Calculate3DDistanceViewController {
        return UIStoryboard(name: "Calculate3DDistance", bundle: nil).instantiateInitialViewController() as! Calculate3DDistanceViewController
    }
    
    func testLoadingView() {
        let viewController = makeViewController()
        
        viewController.loadViewIfNeeded()
        
        if let sceneView = viewController.sceneView {
            XCTAssertNotNil(sceneView.scene)
            if let scene = sceneView.scene {
                XCTAssertEqual(scene.basemap?.name, AGSBasemap.imagery().name)
                XCTAssertNotNil(scene.baseSurface)
                XCTAssertEqual(scene.baseSurface?.elevationSources.count, 1)
            }
            XCTAssertEqual(sceneView.graphicsOverlays.count, 1)
            if let graphicsOverlay = sceneView.graphicsOverlays.firstObject as? AGSGraphicsOverlay {
                XCTAssertEqual(graphicsOverlay.graphics.count, 2)
                XCTAssertEqual(graphicsOverlay.sceneProperties?.surfacePlacement, .absolute)
            }
        } else {
            XCTFail("sceneView is nil")
        }
    }
}

class AbsoluteValueFunctionTests: XCTestCase {
    func testApplyToX() {
        let zeroFunction1 = AbsoluteValueFunction(a: 0, h: 0, k: 0)
        
        XCTAssertEqual(zeroFunction1.apply(to: -1), 0)
        XCTAssertEqual(zeroFunction1.apply(to: 0), 0)
        XCTAssertEqual(zeroFunction1.apply(to: 1), 0)
        
        let function2 = AbsoluteValueFunction(a: -2, h: 0, k: 0)
        
        XCTAssertEqual(function2.apply(to: -1), -2)
        XCTAssertEqual(function2.apply(to: 0), 0)
        XCTAssertEqual(function2.apply(to: 1), -2)
        
        let function3 = AbsoluteValueFunction(a: 1, h: 3, k: 0)
        
        XCTAssertEqual(function3.apply(to: -1), 4)
        XCTAssertEqual(function3.apply(to: 0), 3)
        XCTAssertEqual(function3.apply(to: 1), 2)
        
        let function4 = AbsoluteValueFunction(a: 1, h: 0, k: 7)
        
        XCTAssertEqual(function4.apply(to: -1), 8)
        XCTAssertEqual(function4.apply(to: 0), 7)
        XCTAssertEqual(function4.apply(to: 1), 8)
    }
    
    func testInitWithVertexAndPoint() {
        let vertex = Point(x: 0.1, y: -70)
        let point = Point(x: 0, y: -120)
        let function = AbsoluteValueFunction(vertex: vertex, point: point)
        XCTAssertEqual(function.a, -500)
        XCTAssertEqual(function.h, 0.1)
        XCTAssertEqual(function.k, -70)
    }
}
