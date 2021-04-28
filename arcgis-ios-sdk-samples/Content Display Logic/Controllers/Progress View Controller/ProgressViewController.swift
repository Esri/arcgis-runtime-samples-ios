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
    func showProgressHUD(message: String, duration: TimeInterval? = nil) {
        GlobalProgress.shared.showProgress(message: message, duration: duration, window: window, animated: true)
    }
    func showErrorHUD(error: Error, duration: TimeInterval = 2.0) {
        GlobalProgress.shared.showProgress(message: error.localizedDescription, duration: duration, window: window, animated: false)
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
    
    func showProgress(message: String, duration: TimeInterval?, window: UIWindow?, animated: Bool) {
        // Invalidate old timer, if one exists.
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
        // Update existing progress if already presented.
        if let alertWindow = alertWindow {
            (alertWindow.rootViewController as! PhantomViewController).progressViewController.label.text = message
        } else {
            let progressWindow = UIWindow(frame: window?.frame ?? UIScreen.main.bounds)
            let progressViewController = ProgressViewController()
            progressViewController.loadViewIfNeeded()
            progressViewController.label.text = message
            let phantom = PhantomViewController(progressViewController: progressViewController)
            progressWindow.rootViewController = phantom
            progressWindow.windowLevel = .alert + 1
            progressWindow.makeKeyAndVisible()
            alertWindow = progressWindow
        }
        // Create a timer to dismiss if a duration is set.
        if let duration = duration {
            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [unowned self] _ in
                self.timer = nil
                self.hideProgress()
            }
        }
    }
    
    func hideProgress() {
        guard let window = alertWindow,
              let phantom = window.rootViewController as? PhantomViewController
        else { return }
        
        phantom.progressViewController.dismiss(animated: true) {
            guard let alertWindow = self.alertWindow else { return }
            alertWindow.resignKey()
            self.alertWindow = nil
        }
    }
}

private class ProgressViewController: UIViewController {
    @IBOutlet var label: UILabel!
    @IBOutlet var activityView: UIActivityIndicatorView!
    
    init() {
        super.init(nibName: "ProgressViewController", bundle: Bundle.main)
        view.backgroundColor = backgroundColor(for: traitCollection.userInterfaceStyle)
    }
    
    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = backgroundColor(for: traitCollection.userInterfaceStyle)
    }
    
    func backgroundColor(for userInterfaceStyle: UIUserInterfaceStyle) -> UIColor {
        let backgroundColor: UIColor
        switch userInterfaceStyle {
        case .dark:
            backgroundColor = UIColor.black.withAlphaComponent(0.48)
        default:
            backgroundColor = UIColor.black.withAlphaComponent(0.2)
        }
        return backgroundColor
    }
}

private class PhantomViewController: UIViewController {
    let progressViewController: ProgressViewController
    
    // MARK: - Init
    
    init(progressViewController: ProgressViewController) {
        self.progressViewController = progressViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressViewController.modalTransitionStyle = .crossDissolve
        progressViewController.modalPresentationStyle = .overFullScreen
        present(progressViewController, animated: true)
    }
}
