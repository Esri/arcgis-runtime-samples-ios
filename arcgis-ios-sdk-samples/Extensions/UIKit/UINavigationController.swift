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

extension UINavigationController {
    @discardableResult
    func popToViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) -> [UIViewController]? {
        print(type(of: self), #function, separator: ".")
        let poppedViewControllers = popToViewController(viewController, animated: animated)
        if animated {
            transitionCoordinator?.animate(alongsideTransition: nil) { (_) in
                completion()
            }
        } else {
            completion()
        }
        return poppedViewControllers
    }
    
    func replaceTopViewController(with viewController: UIViewController, animated: Bool) {
        var viewControllers = self.viewControllers
        let indexOfTopViewController = viewControllers.index(before: viewControllers.endIndex)
        viewControllers[indexOfTopViewController] = viewController
        setViewControllers(viewControllers, animated: animated)
    }
}
