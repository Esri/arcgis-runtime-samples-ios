// Copyright 2021 Esri
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

extension UIViewController: GlobalProgressDisplayable {
    var window: UIWindow? { view.window }
}

extension UIApplication: GlobalProgressDisplayable {
    var window: UIWindow? { windows.first }
}

protocol GlobalProgressDisplayable {
    var window: UIWindow? { get }
}

extension GlobalProgressDisplayable {
    func showProgressHUD(_ message: String, duration: TimeInterval? = nil) {
        GlobalProgress.shared.showProgress(message, duration: duration, window: window, animated: true)
    }
    func showErrorHUD(_ error: Error, duration: TimeInterval = 2.0) {
        GlobalProgress.shared.showProgress(error.localizedDescription, duration: duration, window: window, animated: false)
    }
    func hideProgressHUD() {
        GlobalProgress.shared.hideProgress()
    }
}

private class GlobalProgress {
    static let shared = GlobalProgress()
    
    private init() { }
    
    private var alertWindow: UIWindow?
    
    private var timer: Timer?
    
    func showProgress(_ message: String, duration: TimeInterval?, window: UIWindow?, animated: Bool) {
        // Invalidate old timer, if one exists
        timer?.invalidate()
        timer = nil
        // Update existing progress if already presented
        if let alertWindow = alertWindow {
            (alertWindow.rootViewController as! PhantomViewController).progress.label.text = message
        } else {
            let progressWindow = UIWindow(frame: window?.frame ?? UIScreen.main.bounds)
            let progress = ProgressViewController()
            progress.loadViewIfNeeded()
            progress.label.text = message
            let phantom = PhantomViewController(progress)
            progressWindow.rootViewController = phantom
            progressWindow.windowLevel = .alert + 1
            progressWindow.makeKeyAndVisible()
            alertWindow = progressWindow
        }
        // Create a timer to dismiss if a duration is set
        if let duration = duration {
            timer = Timer.scheduledTimer(
                timeInterval: duration,
                target: self,
                selector: #selector(hideProgress),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    @objc
    func hideProgress() {
        guard let window = alertWindow,
              let phantom = window.rootViewController as? PhantomViewController
        else { return }
        
        phantom.progress.dismiss(animated: true) {
            self.alertWindow?.resignKey()
            self.alertWindow = nil
        }
    }
}

private class ProgressViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    init() {
        super.init(nibName: "ProgressViewController", bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var prefersStatusBarHidden: Bool {
        false
    }
}

private class PhantomViewController: UIViewController {
    let progress: ProgressViewController
    
    // MARK: - Init
    
    init(_ progress: ProgressViewController) {
        self.progress = progress
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progress.modalTransitionStyle = .crossDissolve
        progress.modalPresentationStyle = .overFullScreen
        present(progress, animated: true, completion: nil)
    }
}
