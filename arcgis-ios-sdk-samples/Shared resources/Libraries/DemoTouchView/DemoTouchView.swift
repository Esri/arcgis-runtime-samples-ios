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
private struct DemoTouchToken {
    static var showToken: dispatch_once_t = 0
    static var hideToken: dispatch_once_t = 0
    
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
    
    private class var isShowingTouches: Bool {
        return (DemoTouchToken.showToken != 0)
    }
    
    private class func showAllTouches() {
        
        if UIApplication.isShowingTouches {
            return
        }
        
//        print("Enabling demo touches")
        
        DemoTouchToken.resetHide()
        
        dispatch_once(&DemoTouchToken.showToken) {
            
            let originalSelector = #selector(UIApplication.sendEvent(_:))
            let swizzledSelector = #selector(UIApplication.sf_sendEvent(_:))
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            // inject method into the UIApplication class
            //
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            // if it was added, we can replace, else just swap the implementations
            //
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    }
    
    private class func hideAllTouches() {
        
        if !UIApplication.isShowingTouches {
            return
        }
        
        print("Disabling demo touches")
        
        // reset showToken
        //
        DemoTouchToken.resetShow()
        
        dispatch_once(&DemoTouchToken.hideToken) {
            
            let originalSelector = #selector(UIApplication.sendEvent(_:))
            let swizzledSelector = #selector(UIApplication.sf_sendEvent(_:))
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            // put the default implementation back
            //
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        // remove our view
        //
        DemoTouchesView.sharedInstance.removeFromSuperview()
    }
    
    // MARK: - Method Swizzling
    
    func sf_sendEvent(event: UIEvent) {
        
        if let touches = event.allTouches() {
            
            var began: Set<UITouch>?
            var moved: Set<UITouch>?
            var cancelled: Set<UITouch>?
            var ended: Set<UITouch>?
            
            for touch in touches {
                switch touch.phase {
                case .Began:
                    if began == nil {
                        began = Set<UITouch>()
                    }
                    began!.insert(touch)
                case .Moved:
                    if moved == nil {
                        moved = Set<UITouch>()
                    }
                    moved!.insert(touch)
                case .Cancelled:
                    if cancelled == nil {
                        cancelled = Set<UITouch>()
                    }
                    cancelled!.insert(touch)
                case .Ended:
                    if ended == nil {
                        ended = Set<UITouch>()
                    }
                    ended!.insert(touch)
                case .Stationary:
                    // NOTE: I've never actually seen this state.
                    //
                    continue
                }
            }
            
            // dispatch touches to our view
            //
            if let b = began {
                DemoTouchesView.sharedInstance.touchesBegan(b, withEvent: event)
            }
            if let m = moved {
                DemoTouchesView.sharedInstance.touchesMoved(m, withEvent: event)
            }
            if let e = ended {
                DemoTouchesView.sharedInstance.touchesEnded(e, withEvent: event)
            }
            if let c = cancelled {
                DemoTouchesView.sharedInstance.touchesCancelled(c, withEvent: event)
            }
        }
        
        // call original method
        //
        self.sf_sendEvent(event)
    }
}

private class PingLayer: CAShapeLayer, CAAnimationDelegate {
    
    var pingColor: UIColor! {
        didSet {
            strokeColor = pingColor.CGColor
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
            addAnimation(pathAnimation, forKey: "pathAnimation")
            addAnimation(opacityAnimation, forKey: "opacityAnimation")
        }
    }
    
    private let toRadius: CGFloat!
    private let fromRadius: CGFloat!
    private let center: CGPoint!
    
    private lazy var fromPath: CGPath! = {
        
        var fromPath = UIBezierPath()
        fromPath.addArcWithCenter(self.center, radius: self.fromRadius, startAngle: CGFloat(0), endAngle: CGFloat(2.0*M_PI), clockwise: true)
        fromPath.closePath()
        return fromPath.CGPath
        }()
    
    private lazy var toPath: CGPath! = {
        
        var toPath = UIBezierPath()
        toPath.addArcWithCenter(self.center, radius: self.toRadius, startAngle: CGFloat(0), endAngle: CGFloat(2*M_PI), clockwise: true)
        toPath.closePath()
        return toPath.CGPath
        }()
    
    private lazy var pathAnimation: CABasicAnimation = {
        var anim = CABasicAnimation(keyPath: "path")
        anim.duration = 1.0
        anim.fromValue = self.fromPath
        anim.toValue = self.toPath
        anim.removedOnCompletion = true
        anim.delegate = self
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        return anim
        }()
    
    private lazy var opacityAnimation: CABasicAnimation = {
        var anim2 = CABasicAnimation(keyPath: "opacity")
        anim2.duration = self.pingDuration
        anim2.fromValue = 1.0
        anim2.toValue = 0.0
        anim2.removedOnCompletion = true
        anim2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        return anim2
        }()
    
    init(center: CGPoint, fromRadius: CGFloat, toRadius: CGFloat) {
        
        self.center = center
        self.fromRadius = fromRadius
        self.toRadius = toRadius
        self.pingDuration = 1.0
        
        super.init()
        
        fillColor = UIColor.clearColor().CGColor
        strokeColor = UIColor.blueColor().CGColor
        lineWidth = 1
        
        path = fromPath
        
        addAnimation(pathAnimation, forKey: "expandRadius")
        addAnimation(opacityAnimation, forKey: "opacityAnimation")
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: CALayer delegate
    
    @objc private func animationDidStop(anim: CAAnimation, finished flag: Bool) {        
        pathAnimation.delegate = nil
        
        self.removeAllAnimations()
        self.removeFromSuperlayer()
    }
}

// This is the object that should be used for showing/hiding touches
//
public class DemoTouchManager {
    
    // MARK: Properties
    
    public class var touchFillColor: UIColor {
        set {
            DemoTouchesView.sharedInstance.touchFillColor = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchFillColor
        }
    }
    
    public class var touchSize: CGFloat {
        set {
            DemoTouchesView.sharedInstance.touchSize = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchSize
        }
    }
    
    public class var touchBorderColor: UIColor {
        set {
            DemoTouchesView.sharedInstance.touchBorderColor = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchBorderColor
        }
    }
    
    public class var touchBorderWidth: CGFloat {
        set {
            DemoTouchesView.sharedInstance.touchBorderWidth = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.touchBorderWidth
        }
    }
    
    public class var pingWidth: CGFloat {
        set {
            DemoTouchesView.sharedInstance.pingWidth = newValue
        }
        get {
            return DemoTouchesView.sharedInstance.pingWidth
        }
    }
    
    // MARK: Methods
    
    public static func isShowingTouches() -> Bool {
        return UIApplication.isShowingTouches
    }
    
    public static func showTouches() {
        UIApplication.showAllTouches()
    }
    
    public static func hideTouches() {
        UIApplication.hideAllTouches()
    }
}


private class TouchView: UIView {
    
    // MARK: Properties
    
    // This computed property takes into account a tolerance
    // so that two finger single taps can be recognized.
    //
    var moved: Bool {
        let xDist = (center.x - originalCenter.x);
        let yDist = (center.y - originalCenter.y);
        let distance = sqrt((xDist * xDist) + (yDist * yDist));
        return distance > moveTolerance
    }
    
    var moveTolerance: CGFloat = 5
    
    var originalCenter = CGPointZero
    
    // MARK: Initializers
    
    init(center: CGPoint, size: CGSize) {
        
        originalCenter = center
        
        super.init(frame: CGRect(origin: CGPointZero, size:size))
        
        self.center = center
        layer.cornerRadius = size.width / 2.0
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class DemoTouchesView: UIView {
    
    // MARK: Properties
    
    var touchFillColor = UIColor.blueColor()
    var touchSize: CGFloat = 44
    var touchBorderColor = UIColor.whiteColor()
    var touchBorderWidth: CGFloat = 2.0
    var pingWidth: CGFloat = 2.0

    var currentTouches: Set<UITouch>?
    var touchViewMap: [UITouch:TouchView] = [:]
    
    static let sharedInstance: DemoTouchesView = {
        var dtv = DemoTouchesView()
        dtv.backgroundColor = UIColor.clearColor()
        dtv.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        dtv.userInteractionEnabled = false
        return dtv
        }()
    
    // MARK: Methods
    
    func touchViewForPoint(pt: CGPoint) -> TouchView {
        let tv = TouchView(center: pt, size: CGSize(width: touchSize, height: touchSize))
        tv.backgroundColor = touchFillColor
        tv.layer.borderWidth = touchBorderWidth
        tv.layer.borderColor = touchBorderColor.CGColor
        return tv
    }
    
    func pingLayerForTouch(touch: UITouch) -> PingLayer {
        let pl = PingLayer(center: touch.locationInView(self), fromRadius: 0, toRadius: touchSize)
        pl.pingWidth = pingWidth
        pl.pingColor = touchFillColor
        return pl
    }
    
    func updateTouches(touches: Set<NSObject>?) {
        
        currentTouches = touches as? Set<UITouch>
        
        if let w = UIApplication.sharedApplication().keyWindow {
            
            if DemoTouchesView.sharedInstance.window == nil {
                DemoTouchesView.sharedInstance.frame = w.frame
                w.addSubview(DemoTouchesView.sharedInstance)
            } else {

                // Ensure our DemoTouch view is always at the front of it's window
                //
                DemoTouchesView.sharedInstance.window!.bringSubviewToFront(DemoTouchesView.sharedInstance)
            }
        }
        
        if let touches = currentTouches {
            for touch in touches {
                switch touch.phase {
                case .Began:
                    addTouch(touch)
                case .Moved:
                    moveTouch(touch)
                case .Ended:
                    removeTouch(touch)
                case .Cancelled:
                    removeTouch(touch, cancelled: true)
                case .Stationary:
                    // NOTE: I've never actually seen this state.
                    //
                    continue
                }
            }
        }
    }
    
    private func addTouch(touch: UITouch) {
        let pt = touch.locationInView(self)
        let newTV = touchViewForPoint(pt)
        
        DemoTouchesView.sharedInstance.addSubview(newTV)
        touchViewMap[touch] = newTV
    }
    
    private func moveTouch(touch: UITouch) {
        if let tv = touchViewMap[touch] {
            let pt = touch.locationInView(self)
            tv.center = pt
        }
    }
    
    private func removeTouch(touch: UITouch, cancelled: Bool = false) {
        if let tv = touchViewMap[touch] {

            let animations: (()->Void) = {
                tv.transform = CGAffineTransformMakeScale(0.1, 0.1)
                tv.alpha = 0.0
                
                // only show the ping for a non-cancelled touch that hasn't moved (a touch that actually ended)
                // basically, a single tap
                //
                if !cancelled && !tv.moved {
                    self.showPingForTouch(touch)
                }
            }
            UIView.animateWithDuration(0.25, animations: animations) { (finished) in
                tv.removeFromSuperview()
            }
            
            // stop tracking the touch
            //
            touchViewMap[touch] = nil
        }
    }
    
    // This method is for future use if we want to show tap and hold
    //
    private func intensifyTouchView(touch: UITouch) {
        
        if let tv = touchViewMap[touch] {
            
            if tv.alpha < 1.0 {
                tv.alpha += CGFloat(0.05)
            }
        }
    }
    
    private func showPingForTouch(touch: UITouch) {
        showPingForTouches([touch])
    }
    
    private func showPingForTouches(touches: [UITouch]) {
        
        for touch in touches {
            let pingLyr = pingLayerForTouch(touch)
            DemoTouchesView.sharedInstance.layer.addSublayer(pingLyr)
        }
    }
    
    private override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        updateTouches(touches)
    }
    
    private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        updateTouches(touches)
    }
    
    private override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        updateTouches(touches)
    }
    
    private override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
        updateTouches(touches)
    }
}
