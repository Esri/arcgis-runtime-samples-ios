// Copyright 2016 Esri.
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

private extension UIApplication {
    @objc
    func sf_sendEvent(_ event: UIEvent) {
        DemoTouchManager.shared.handleEvent(event)
        // Call the original method.
        sf_sendEvent(event)
    }
}

private class PingLayer: CAShapeLayer, CAAnimationDelegate {
    var pingColor: UIColor! {
        didSet {
            strokeColor = pingColor.cgColor
        }
    }
    
    var pingWidth: CGFloat = 1.0 {
        didSet {
            lineWidth = pingWidth
        }
    }
    
    var pingDuration: TimeInterval = 1.0 {
        didSet {
            pathAnimation.duration = pingDuration
            opacityAnimation.duration = pingDuration
            
            removeAllAnimations()
            add(pathAnimation, forKey: "pathAnimation")
            add(opacityAnimation, forKey: "opacityAnimation")
        }
    }
    
    let center: CGPoint
    let fromRadius: CGFloat
    let toRadius: CGFloat
    
    lazy var fromPath: CGPath = { [unowned self] in
        let fromPath = UIBezierPath()
        fromPath.addArc(withCenter: self.center, radius: self.fromRadius, startAngle: 0, endAngle: 2.0 * .pi, clockwise: true)
        fromPath.close()
        return fromPath.cgPath
    }()
    
    lazy var toPath: CGPath = { [unowned self] in
        let toPath = UIBezierPath()
        toPath.addArc(withCenter: self.center, radius: self.toRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        toPath.close()
        return toPath.cgPath
    }()
    
    lazy var pathAnimation: CABasicAnimation = { [unowned self] in
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        animation.duration = 1.0
        animation.fromValue = fromPath
        animation.toValue = toPath
        animation.isRemovedOnCompletion = true
        animation.delegate = self
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return animation
    }()
    
    lazy var opacityAnimation: CABasicAnimation = { [unowned self] in
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.opacity))
        animation.duration = pingDuration
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return animation
    }()
    
    init(center: CGPoint, fromRadius: CGFloat, toRadius: CGFloat) {
        self.center = center
        self.fromRadius = fromRadius
        self.toRadius = toRadius
        self.pingDuration = 1.0
        
        super.init()
        
        fillColor = UIColor.clear.cgColor
        strokeColor = UIColor.blue.cgColor
        lineWidth = 1
        
        path = fromPath
        
        add(pathAnimation, forKey: "expandRadius")
        add(opacityAnimation, forKey: "opacityAnimation")
    }
    
    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: CALayer delegate
    
    @objc
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        pathAnimation.delegate = nil
        
        removeAllAnimations()
        removeFromSuperlayer()
    }
}

/// `DemoTouchManager` can be used for showing/hiding touches.
class DemoTouchManager {
    static let shared = DemoTouchManager()
    
    private let view = DemoTouchesView()
    
    private init() {}
    
    // MARK: Properties
    
    var touchFillColor: UIColor {
        get {
            return view.touchFillColor
        }
        set {
            view.touchFillColor = newValue
        }
    }
    
    var touchSize: CGFloat {
        get {
            return view.touchSize
        }
        set {
            view.touchSize = newValue
        }
    }
    
    var touchBorderColor: UIColor {
        get {
            return view.touchBorderColor
        }
        set {
            view.touchBorderColor = newValue
        }
    }
    
    var touchBorderWidth: CGFloat {
        get {
            return view.touchBorderWidth
        }
        set {
            view.touchBorderWidth = newValue
        }
    }
    
    var pingWidth: CGFloat {
        get {
            return view.pingWidth
        }
        set {
            view.pingWidth = newValue
        }
    }
    
    // MARK: Methods
    
    private(set) var isShowingTouches = false
    
    func showTouches() {
        guard !isShowingTouches else { return }
        defer { isShowingTouches = true }
        
        let originalSelector = #selector(UIApplication.sendEvent)
        let swizzledSelector = #selector(UIApplication.sf_sendEvent)
        
        guard let originalMethod = class_getInstanceMethod(UIApplication.self, originalSelector), let swizzledMethod = class_getInstanceMethod(UIApplication.self, swizzledSelector) else {
            fatalError("Cannot swizzle with nil method.")
        }
        
        // Inject method into the UIApplication class.
        let didAddMethod = class_addMethod(UIApplication.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        // If it was added, we can replace, else just swap the implementations.
        if didAddMethod {
            class_replaceMethod(UIApplication.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        // The key window might not be available right now, so we'll add the
        // view on demand when needed.
    }
    
    func hideTouches() {
        guard isShowingTouches else { return }
        defer { isShowingTouches = false }
        
        let originalSelector = #selector(UIApplication.sendEvent)
        let swizzledSelector = #selector(UIApplication.sf_sendEvent)
        
        guard let originalMethod = class_getInstanceMethod(UIApplication.self, originalSelector), let swizzledMethod = class_getInstanceMethod(UIApplication.self, swizzledSelector) else {
            fatalError("Cannot swizzle with nil method.")
        }
        
        // Put the default implementation back.
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        // Remove our view.
        view.removeFromSuperview()
    }
    
    func handleEvent(_ event: UIEvent) {
        guard let touches = event.allTouches else { return }
        // Ensure our DemoTouch view is always at the front of its window.
        if let window = view.window {
            window.bringSubviewToFront(view)
        } else {
            UIApplication.shared.keyWindow?.addSubview(view)
        }
        view.updateTouches(touches)
    }
}

private class TouchView: UIView {
    // MARK: Properties
    
    // This computed property takes into account a tolerance
    // so that two finger single taps can be recognized.
    var moved: Bool {
        let xDist = center.x - originalCenter.x
        let yDist = center.y - originalCenter.y
        let distance = (xDist * xDist + yDist * yDist).squareRoot()
        return distance > moveTolerance
    }
    
    let moveTolerance: CGFloat = 5
    
    let originalCenter: CGPoint
    
    // MARK: Initializers
    
    init(center: CGPoint, size: CGSize) {
        originalCenter = center
        
        super.init(frame: CGRect(origin: .zero, size: size))
        
        self.center = center
        layer.cornerRadius = size.width / 2.0
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class DemoTouchesView: UIView {
    // MARK: Properties
    
    var touchFillColor = UIColor.blue
    var touchSize: CGFloat = 44
    var touchBorderColor = UIColor.white
    var touchBorderWidth: CGFloat = 2.0
    var pingWidth: CGFloat = 2.0

    var currentTouches: Set<UITouch>?
    var touchViewMap: [UITouch: TouchView] = [:]
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    func makeTouchView(point: CGPoint) -> TouchView {
        let touchView = TouchView(center: point, size: CGSize(width: touchSize, height: touchSize))
        touchView.backgroundColor = touchFillColor
        touchView.layer.borderWidth = touchBorderWidth
        touchView.layer.borderColor = touchBorderColor.cgColor
        return touchView
    }
    
    func makePingLayer(touch: UITouch) -> PingLayer {
        let pingLayer = PingLayer(center: touch.location(in: self), fromRadius: 0, toRadius: touchSize)
        pingLayer.pingWidth = pingWidth
        pingLayer.pingColor = touchFillColor
        return pingLayer
    }
    
    func updateTouches<S: Sequence>(_ touches: S) where S.Element == UITouch {
        touches.forEach { (touch) in
            switch touch.phase {
            case .began:
                addTouch(touch)
            case .moved:
                moveTouch(touch)
            case .ended:
                removeTouch(touch)
            case .cancelled:
                removeTouch(touch, cancelled: true)
            case .stationary:
                // NOTE: I've never actually seen this state.
                break
            @unknown default:
                break
            }
        }
    }
    
    func addTouch(_ touch: UITouch) {
        let touchLocation = touch.location(in: self)
        let newTouchView = makeTouchView(point: touchLocation)
        
        addSubview(newTouchView)
        touchViewMap[touch] = newTouchView
    }
    
    func moveTouch(_ touch: UITouch) {
        guard let touchView = touchViewMap[touch] else { return }
        let touchLocation = touch.location(in: self)
        touchView.center = touchLocation
    }
    
    func removeTouch(_ touch: UITouch, cancelled: Bool = false) {
        guard let touchView = touchViewMap[touch] else { return }
        
        // swiftlint:disable multiline_arguments
        UIView.animate(withDuration: 0.25, animations: {
            touchView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            touchView.alpha = 0.0
            
            // Only show the ping for a non-cancelled touch that hasn't moved (a
            // touch that actually ended) basically, a single tap.
            if !cancelled && !touchView.moved {
                self.showPing(for: [touch])
            }
        }, completion: { _ in
            touchView.removeFromSuperview()
        })
        // swiftlint:enable multiline_arguments
        
        // Stop tracking the touch.
        touchViewMap[touch] = nil
    }
    
    // This method is for future use if we want to show tap and hold.
    func intensifyTouchView(_ touch: UITouch) {
        guard let touchView = touchViewMap[touch] else { return }
        if touchView.alpha < 1.0 {
            touchView.alpha += 0.05
        }
    }

    func showPing<S: Sequence>(for touches: S) where S.Element == UITouch {
        touches.forEach { (touch) in
            let pingLayer = makePingLayer(touch: touch)
            layer.addSublayer(pingLayer)
        }
    }
}
