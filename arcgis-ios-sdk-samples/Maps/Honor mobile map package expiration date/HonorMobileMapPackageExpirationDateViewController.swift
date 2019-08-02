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
import ArcGIS

/// A view controller that manages the interface of the Honor Mobile Map Package
// Expiration Date sample.
class HonorMobileMapPackageExpirationDateViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            loadMobileMapPackage()
        }
    }
    @IBOutlet weak var expirationView: UIView!
    @IBOutlet weak var expirationMessageLabel: UILabel!
    @IBOutlet weak var timeToExpirationLabel: UILabel!
    
    /// The mobile map package used by this sample.
    let mobileMapPackage = AGSMobileMapPackage(fileURL: Bundle.main.url(forResource: "LothianRiversAnno", withExtension: "mmpk")!)
    /// The timer used to update the time-to-expiration label.
    var timeToExpirationTimer: Timer?
    
    /// Initiates loading of the mobile map package.
    func loadMobileMapPackage() {
        mobileMapPackage.load { [weak self] (error) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            self?.mobileMapPackageDidLoad(with: result)
        }
    }
    
    /// Called in response to the mobile map package load operation completing.
    ///
    /// - Parameter result: The result of the load operation.
    func mobileMapPackageDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            mapView.map = mobileMapPackage.maps.first
            // Is the package expired? If so, then we'll want to show the
            // expiration view.
            if let expiration = mobileMapPackage.expiration, expiration.isExpired {
                expirationMessageLabel.text = expiration.message
                // Does the package have an expiration date? If so, we'll want
                // to show the time-to-expiration label.
                if expiration.dateTime != nil {
                    let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [unowned self] (_) in
                        self.updateTimeToExpiration()
                    }
                    timer.tolerance = 0.1
                    timer.fire()
                    timeToExpirationTimer = timer
                    timeToExpirationLabel.isHidden = false
                }
                expirationView.isHidden = false
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Updates the time-to-expiration label with an expiration message relative
    /// to the current time.
    func updateTimeToExpiration() {
        guard let expirationDate = mobileMapPackage.expiration?.dateTime else {
            return
        }
        let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: expirationDate, to: Date())
        let text: String
        if let string = DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .abbreviated) {
            text = String(format: "Expired %@ ago.", string)
        } else {
            text = ""
        }
        self.timeToExpirationLabel.text = text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "HonorMobileMapPackageExpirationDateViewController"
        ]
    }
    
    deinit {
        timeToExpirationTimer?.invalidate()
    }
}
