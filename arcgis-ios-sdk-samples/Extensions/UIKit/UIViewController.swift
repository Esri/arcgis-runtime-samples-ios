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

extension UIViewController {
    
    /// Shows an alert with the given title, message, and an OK button.
    func presentAlert(title: String? = nil, message: String) {
        let okAction = UIAlertAction(title: "OK", style: .default)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert, actions: [okAction])
        present(alertController, animated: true)
    }
    
    /// Show an alert with the title "Error", the error's `localizedDescription`
    /// as the message, and an OK button.
    func presentAlert(error: Error) {
        presentAlert(title: "Error", message: error.localizedDescription)
    }
    
}

extension UIAlertController {
    
    /// Initializes the alert controller with the given parameters, adding the
    /// actions successively and setting the first action as preferred.
    fileprivate convenience init(title: String? = nil, message: String? = nil, preferredStyle: UIAlertController.Style = .alert, actions: [UIAlertAction] = []) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        for action in actions {
            addAction(action)
        }
        preferredAction = actions.first
    }
}
