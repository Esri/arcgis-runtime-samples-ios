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

extension UIApplication {
    @objc fileprivate func sf_sendEvent(_ event: UIEvent) {
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
    
    var pingWidth: CGFloat {
        set {
            lineWidth = newValue
        }
        get {
            return lineWidth
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
    
    fileprivate let toRadius: CGFloat!
    fileprivate let fromRadius: CGFloat!
    fileprivate let center: CGPoint!
    
    fileprivate lazy var fromPath: CGPath = {
        var fromPath = UIBezierPath()
        fromPath.addArc(withCenter: self.center, radius: self.fromRadius, startAngle: CGFloat(0), endAngle: 2.0 * CGFloat.pi, clockwise: true)
        fromPath.close()
        return fromPath.cgPath
    }()
    
    fileprivate lazy var toPath: CGPath = {
        var toPath = UIBezierPath()
        toPath.addArc(withCenter: self.center, radius: self.toRadius, startAngle: CGFloat(0), endAngle: 2 * CGFloat.pi, clockwise: true)
        toPath.close()
        return toPath.cgPath
    }()
    
    fileprivate lazy var pathAnimation: CABasicAnimation = {
        var anim = CABasicAnimation(keyPath: "path")
        anim.duration = 1.0
        anim.fromValue = fromPath
        anim.toValue = toPath
        anim.isRemovedOnCompletion = true
        anim.delegate = self
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        return anim
    }()
    
    fileprivate lazy var opacityAnimation: CABasicAnimation = {
        var anim2 = CABasicAnimation(keyPath: "opacity")
        anim2.duration = pingDuration
        anim2.fromValue = 1.0
        anim2.toValue = 0.0
        anim2.isRemovedOnCompletion = true
        anim2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        return anim2
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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: CALayer delegate
    
    @objc fileprivate func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {        
        pathAnimation.delegate = nil
        
        removeAllAnimations()
        removeFromSuperlayer()
    }
}

// This is the object that should be used for showing/hiding touches.
public class DemoTouchManager {
    static let shared = DemoTouchManager()
    
    private let view = DemoTouchesView()
    
    private init() {}
    
    // MARK: Properties
    
    public var touchFillColor: UIColor {
        get {
            return view.touchFillColor
        }
        set {
            view.touchFillColor = newValue
        }
    }
    
    public var touchSize: CGFloat {
        get {
            return view.touchSize
        }
        set {
            view.touchSize = newValue
        }
    }
    
    public var touchBorderColor: UIColor {
        get {
            return view.touchBorderColor
        }
        set {
            view.touchBorderColor = newValue
        }
    }
    
    public var touchBorderWidth: CGFloat {
        get {
            return view.touchBorderWidth
        }
        set {
            view.touchBorderWidth = newValue
        }
    }
    
    public var pingWidth: CGFloat {
        get {
            return view.pingWidth
        }
        set {
            view.pingWidth = newValue
        }
    }
    
    // MARK: Methods
    
    public private(set) var isShowingTouches = false
    
    public func showTouches() {
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
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
    
    public func hideTouches() {
        guard isShowingTouches else { return }
        defer { isShowingTouches = false }
        
        let originalSelector = #selector(UIApplication.sendEvent)
        let swizzledSelector = #selector(UIApplication.sf_sendEvent)
        
        guard let originalMethod = class_getInstanceMethod(UIApplication.self, originalSelector), let swizzledMethod = class_getInstanceMethod(UIApplication.self, swizzledSelector) else {
            fatalError("Cannot swizzle with nil method.")
        }
        
        // Put the default implementation back.
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        // Remove our view.
        view.removeFromSuperview()
    }
    
    func handleEvent(_ event: UIEvent) {
        guard let touches = event.allTouches else { return }
        
        var began = Set<UITouch>()
        var moved = Set<UITouch>()
        var cancelled = Set<UITouch>()
        var ended = Set<UITouch>()
        
        for touch in touches {
            switch touch.phase {
            case .began:
                began.insert(touch)
            case .moved:
                moved.insert(touch)
            case .cancelled:
                cancelled.insert(touch)
            case .ended:
                ended.insert(touch)
            case .stationary:
                // NOTE: I've never actually seen this state.
                continue
            }
        }
        
        UIApplication.shared.keyWindow?.addSubview(view)
        // Dispatch touches to our view.
        if !began.isEmpty {
            view.touchesBegan(began, with: event)
        }
        if !moved.isEmpty {
            view.touchesMoved(moved, with: event)
        }
        if !ended.isEmpty {
            view.touchesEnded(ended, with: event)
        }
        if !cancelled.isEmpty {
            view.touchesCancelled(cancelled, with: event)
        }
    }
}


private class TouchView: UIView {
    // MARK: Properties
    
    // This computed property takes into account a tolerance
    // so that two finger single taps can be recognized.
    var moved: Bool {
        let xDist = (center.x - originalCenter.x);
        let yDist = (center.y - originalCenter.y);
        let distance = sqrt((xDist * xDist) + (yDist * yDist));
        return distance > moveTolerance
    }
    
    var moveTolerance: CGFloat = 5
    
    var originalCenter = CGPoint.zero
    
    // MARK: Initializers
    
    init(center: CGPoint, size: CGSize) {
        originalCenter = center
        
        super.init(frame: CGRect(origin: .zero, size: size))
        
        self.center = center
        layer.cornerRadius = size.width / 2.0
    }

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
        let tv = TouchView(center: point, size: CGSize(width: touchSize, height: touchSize))
        tv.backgroundColor = touchFillColor
        tv.layer.borderWidth = touchBorderWidth
        tv.layer.borderColor = touchBorderColor.cgColor
        return tv
    }
    
    func makePingLayer(touch: UITouch) -> PingLayer {
        let pl = PingLayer(center: touch.location(in: self), fromRadius: 0, toRadius: touchSize)
        pl.pingWidth = pingWidth
        pl.pingColor = touchFillColor
        return pl
    }
    
    func updateTouches(_ touches: Set<NSObject>?) {
        currentTouches = touches as? Set<UITouch>
        
        // Ensure our DemoTouch view is always at the front of its window.
        window?.bringSubview(toFront: self)
        
        if let touches = currentTouches {
            for touch in touches {
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
                    //
                    continue
                }
            }
        }
    }
    
    func addTouch(_ touch: UITouch) {
        let pt = touch.location(in: self)
        let newTV = makeTouchView(point: pt)
        
        addSubview(newTV)
        touchViewMap[touch] = newTV
    }
    
    func moveTouch(_ touch: UITouch) {
        guard let touchView = touchViewMap[touch] else { return }
        let pt = touch.location(in: self)
        touchView.center = pt
    }
    
    func removeTouch(_ touch: UITouch, cancelled: Bool = false) {
        guard let touchView = touchViewMap[touch] else { return }
        let animations: (()->Void) = {
            touchView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            touchView.alpha = 0.0
            
            // Only show the ping for a non-cancelled touch that hasn't moved (a
            // touch that actually ended) basically, a single tap.
            if !cancelled && !touchView.moved {
                self.showPing(for: [touch])
            }
        }
        UIView.animate(withDuration: 0.25, animations: animations, completion: { (finished) in
            touchView.removeFromSuperview()
        })
        
        // Stop tracking the touch.
        touchViewMap[touch] = nil
    }
    
    // This method is for future use if we want to show tap and hold.
    func intensifyTouchView(_ touch: UITouch) {
        guard let touchView = touchViewMap[touch] else { return }
        if touchView.alpha < 1.0 {
            touchView.alpha += CGFloat(0.05)
        }
    }
    
    func showPing<S: Sequence>(for touches: S) where S.Element == UITouch {
        for touch in touches {
            let pingLayer = makePingLayer(touch: touch)
            layer.addSublayer(pingLayer)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(touches)
    }
}
