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

import Foundation
import UIKit

// Used to keep track of whether we are currently showing touches
//
private enum DemoTouchToken {
    static var showToken: Int = 0
    static var hideToken: Int = 0
    
    static func resetShow() {
        DemoTouchToken.showToken = 0
    }
    
    static func resetHide() {
        DemoTouchToken.hideToken = 0
    }
}

// NOTE: This must not be made private or the swizzling will not work
//
extension UIApplication {
    
    fileprivate class var isShowingTouches: Bool {
        return (DemoTouchToken.showToken != 0)
    }
    
    fileprivate class func showAllTouches() {
        
        if UIApplication.isShowingTouches {
            return
        }
        
//        print("Enabling demo touches")
        
        DemoTouchToken.resetHide()
        
        if DemoTouchToken.showToken == 0 {
            DemoTouchToken.showToken = 1
            let originalSelector = #selector(sendEvent)
            let swizzledSelector = #selector(sf_sendEvent)
            
            guard let originalMethod = class_getInstanceMethod(self, originalSelector), let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
                fatalError("Cannot swizzle with nil method.")
            }
            
            // inject method into the UIApplication class
            //
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            // if it was added, we can replace, else just swap the implementations
            //
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    fileprivate class func hideAllTouches() {
        
        if !UIApplication.isShowingTouches {
            return
        }
        
        print("Disabling demo touches")
        
        // reset showToken
        //
        DemoTouchToken.resetShow()
        
        if DemoTouchToken.hideToken == 0 {
            DemoTouchToken.hideToken = 1
            let originalSelector = #selector(sendEvent)
            let swizzledSelector = #selector(sf_sendEvent)
            
            guard let originalMethod = class_getInstanceMethod(self, originalSelector), let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
                fatalError("Cannot swizzle with nil method.")
            }
            
            // put the default implementation back
            //
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        // remove our view
        //
        DemoTouchesView.sharedInstance.removeFromSuperview()
    }
    
    // MARK: - Method Swizzling
    
    @objc
    func sf_sendEvent(_ event: UIEvent) {
        
        if let touches = event.allTouches {
            
            let began: Set<UITouch> = touches.filter { $0.phase == .began }
            let moved: Set<UITouch> = touches.filter { $0.phase == .moved }
            let cancelled: Set<UITouch> = touches.filter { $0.phase == .cancelled }
            let ended: Set<UITouch> = touches.filter { $0.phase == .ended }
            
            // dispatch touches to our view
            if !began.isEmpty {
                DemoTouchesView.sharedInstance.touchesBegan(began, with: event)
            }
            if !moved.isEmpty {
                DemoTouchesView.sharedInstance.touchesMoved(moved, with: event)
            }
            if !ended.isEmpty {
                DemoTouchesView.sharedInstance.touchesEnded(ended, with: event)
            }
            if !cancelled.isEmpty {
                DemoTouchesView.sharedInstance.touchesCancelled(cancelled, with: event)
            }
        }
        
        // call original method
        self.sf_sendEvent(event)
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
    
    var pingDuration: Double = 1.0 {
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
    
    fileprivate lazy var fromPath: CGPath! = {
        
        var fromPath = UIBezierPath()
        fromPath.addArc(withCenter: self.center, radius: self.fromRadius, startAngle: CGFloat(0), endAngle: 2.0 * CGFloat.pi, clockwise: true)
        fromPath.close()
        return fromPath.cgPath
        }()
    
    fileprivate lazy var toPath: CGPath! = {
        
        var toPath = UIBezierPath()
        toPath.addArc(withCenter: self.center, radius: self.toRadius, startAngle: CGFloat(0), endAngle: 2 * CGFloat.pi, clockwise: true)
        toPath.close()
        return toPath.cgPath
        }()
    
    fileprivate lazy var pathAnimation: CABasicAnimation = {
        var anim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        anim.duration = 1.0
        anim.fromValue = self.fromPath
        anim.toValue = self.toPath
        anim.isRemovedOnCompletion = true
        anim.delegate = self
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return anim
        }()
    
    fileprivate lazy var opacityAnimation: CABasicAnimation = {
        var anim2 = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.opacity))
        anim2.duration = self.pingDuration
        anim2.fromValue = 1.0
        anim2.toValue = 0.0
        anim2.isRemovedOnCompletion = true
        anim2.timingFunction = CAMediaTimingFunction(name: .easeOut)
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
    
    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: CALayer delegate
    
    @objc
    fileprivate func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {        
        pathAnimation.delegate = nil
        
        self.removeAllAnimations()
        self.removeFromSuperlayer()
    }
}

// This is the object that should be used for showing/hiding touches
//
enum DemoTouchManager {
    
    // MARK: Properties
    
    static var touchFillColor: UIColor {
        set {
            DemoTouchesView.sharedInstance.touchFillColor = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchFillColor
        }
    }
    
    static var touchSize: CGFloat {
        set {
            DemoTouchesView.sharedInstance.touchSize = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchSize
        }
    }
    
    static var touchBorderColor: UIColor {
        set {
            DemoTouchesView.sharedInstance.touchBorderColor = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchBorderColor
        }
    }
    
    static var touchBorderWidth: CGFloat {
        set {
            DemoTouchesView.sharedInstance.touchBorderWidth = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchBorderWidth
        }
    }
    
    static var pingWidth: CGFloat {
        set {
            DemoTouchesView.sharedInstance.pingWidth = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.pingWidth
        }
    }
    
    // MARK: Methods
    
    static func isShowingTouches() -> Bool {
        return UIApplication.isShowingTouches
    }
    
    static func showTouches() {
        UIApplication.showAllTouches()
    }
    
    static func hideTouches() {
        UIApplication.hideAllTouches()
    }
}

private class TouchView: UIView {
    
    // MARK: Properties
    
    // This computed property takes into account a tolerance
    // so that two finger single taps can be recognized.
    //
    var moved: Bool {
        let xDist = center.x - originalCenter.x
        let yDist = center.y - originalCenter.y
        let distance = (xDist * xDist + yDist * yDist).squareRoot()
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
    
    static let sharedInstance: DemoTouchesView = {
        var dtv = DemoTouchesView()
        dtv.backgroundColor = .clear
        dtv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dtv.isUserInteractionEnabled = false
        return dtv
        }()
    
    // MARK: Methods
    
    func touchViewForPoint(_ point: CGPoint) -> TouchView {
        let touchView = TouchView(center: point, size: CGSize(width: touchSize, height: touchSize))
        touchView.backgroundColor = touchFillColor
        touchView.layer.borderWidth = touchBorderWidth
        touchView.layer.borderColor = touchBorderColor.cgColor
        return touchView
    }
    
    func pingLayerForTouch(_ touch: UITouch) -> PingLayer {
        let pingLayer = PingLayer(center: touch.location(in: self), fromRadius: 0, toRadius: touchSize)
        pingLayer.pingWidth = pingWidth
        pingLayer.pingColor = touchFillColor
        return pingLayer
    }
    
    func updateTouches(_ touches: Set<NSObject>?) {
        
        currentTouches = touches as? Set<UITouch>
        
        if let window = UIApplication.shared.keyWindow {
            
            if DemoTouchesView.sharedInstance.window == nil {
                DemoTouchesView.sharedInstance.frame = window.frame
                window.addSubview(DemoTouchesView.sharedInstance)
            } else {

                // Ensure our DemoTouch view is always at the front of it's window
                //
                DemoTouchesView.sharedInstance.window!.bringSubviewToFront(DemoTouchesView.sharedInstance)
            }
        }
        
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
    
    fileprivate func addTouch(_ touch: UITouch) {
        let touchLocation = touch.location(in: self)
        let newTouchView = touchViewForPoint(touchLocation)
        
        DemoTouchesView.sharedInstance.addSubview(newTouchView)
        touchViewMap[touch] = newTouchView
    }
    
    fileprivate func moveTouch(_ touch: UITouch) {
        if let touchView = touchViewMap[touch] {
            let touchLocation = touch.location(in: self)
            touchView.center = touchLocation
        }
    }
    
    fileprivate func removeTouch(_ touch: UITouch, cancelled: Bool = false) {
        if let touchView = touchViewMap[touch] {

            let animations: (() -> Void) = {
                touchView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                touchView.alpha = 0.0
                
                // only show the ping for a non-cancelled touch that hasn't moved (a touch that actually ended)
                // basically, a single tap
                //
                if !cancelled && !touchView.moved {
                    self.showPingForTouch(touch)
                }
            }
            UIView.animate(withDuration: 0.25, animations: animations, completion: { (finished) in
                touchView.removeFromSuperview()
            }) 
            
            // stop tracking the touch
            //
            touchViewMap[touch] = nil
        }
    }
    
    // This method is for future use if we want to show tap and hold
    //
    fileprivate func intensifyTouchView(_ touch: UITouch) {
        
        if let touchView = touchViewMap[touch] {
            
            if touchView.alpha < 1.0 {
                touchView.alpha += CGFloat(0.05)
            }
        }
    }
    
    fileprivate func showPingForTouch(_ touch: UITouch) {
        showPingForTouches([touch])
    }
    
    fileprivate func showPingForTouches(_ touches: [UITouch]) {
        
        for touch in touches {
            let pingLyr = pingLayerForTouch(touch)
            DemoTouchesView.sharedInstance.layer.addSublayer(pingLyr)
        }
    }
    
    override fileprivate func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        updateTouches(touches)
    }
    
    override fileprivate func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        updateTouches(touches)
    }
    
    override fileprivate func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        updateTouches(touches)
    }
    
    override fileprivate func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        
        updateTouches(touches)
    }
}
