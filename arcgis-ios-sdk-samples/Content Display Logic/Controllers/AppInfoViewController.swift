// Copyright 2021 Esri.
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

import SwiftUI

class AppInfoViewController: UIHostingController<AppInfoView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: AppInfoView())
        self.title = "App Info"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
    }
    
    @objc
    func doneButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
}
