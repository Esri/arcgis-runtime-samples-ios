// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import SwiftUI

class DisplayMapSwiftUIViewController: UIHostingController<DisplayMapSwiftUIView> {
    required init?(coder: NSCoder) {
        // `UIHostingController` integrates SwiftUI views into a UIKit
        // view hierarchy. At creation time, specify the SwiftUI as the
        // root view for this view controller.
        super.init(coder: coder, rootView: DisplayMapSwiftUIView())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "SwiftUIMapView",
            "DisplayMapSwiftUIView",
            "DisplayMapSwiftUIViewController"
        ]
    }
}
