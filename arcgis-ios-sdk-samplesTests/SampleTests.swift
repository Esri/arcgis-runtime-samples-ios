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
@testable import arcgis_ios_sdk_samples

class SampleTests: XCTestCase {
    func testInitFromDecoder() {
        let sampleData = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
                <dict>
                    <key>displayName</key>
                    <string>Blend renderer</string>
                    <key>storyboardName</key>
                    <string>BlendRenderer</string>
                    <key>descriptionText</key>
                    <string>The sample shows you how to use blend renderer with raster layer</string>
                    <key>dependency</key>
                    <array>
                        <string>ShastaElevationRaster</string>
                        <string>ShastaRaster</string>
                    </array>
                </dict>
            </plist>
        """.data(using: .utf8)!
        let expectedSample = Sample(
            name: "Blend renderer",
            description: "The sample shows you how to use blend renderer with raster layer",
            storyboardName: "BlendRenderer",
            dependencies: ["ShastaElevationRaster", "ShastaRaster"]
        )
        XCTAssertEqual(try PropertyListDecoder().decode(Sample.self, from: sampleData), expectedSample)
    }
}
