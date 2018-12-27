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
