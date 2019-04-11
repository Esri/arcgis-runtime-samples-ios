// Copyright 2019 Esri.
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
import ArcGIS

protocol CameraControllerTableViewControllerDelagate: AnyObject {
    func selectedCameraControllerChanged(_ tableViewController: CameraControllerTableViewController)
}

class CameraControllerTableViewController: UITableViewController {
    weak var delegate: CameraControllerTableViewControllerDelagate?
    var cameraControllers = [AGSCameraController]()
    var selectedCameraController: AGSCameraController?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedCameraController = selectedCameraController, let selectedRow = cameraControllers.firstIndex(where: { type(of: $0) == type(of: selectedCameraController) }) {
            tableView.selectRow(at: IndexPath(row: selectedRow, section: 0), animated: false, scrollPosition: .none)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameraControllers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = getDescription(of: cameraControllers[indexPath.row])
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCameraController = cameraControllers[indexPath.row]
        delegate?.selectedCameraControllerChanged(self)
    }
    
    // MARK: - Helper method
    
    /// Gets description of the specified camera controller.
    ///
    /// - Parameter cameraController: Camera controller of scene view.
    /// - Returns: A text description of the camera controller.
    func getDescription(of cameraController: AGSCameraController) -> String {
        if cameraController is AGSOrbitGeoElementCameraController {
            return "Orbit camera around plane"
        } else if cameraController is AGSOrbitLocationCameraController {
            return "Orbit camera around crater"
        } else {
            return "Free pan round the globe"
        }
    }
}
