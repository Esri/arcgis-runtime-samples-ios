// Copyright 2015 Esri.
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

//TODO: Add logic to change direction of menu at runtime

import UIKit

protocol CustomContextSheetDelegate:class {
    func customContextSheet(customContextSheet:CustomContextSheet, didSelectItemAtIndex index:Int)
}

class CustomContextSheet: UIView {

    private let animationDuration:CFTimeInterval = 0.3
    private let buttonSize:CGFloat = 44
    private let buttonDisplacement:CGFloat = 50
    
    var titles:[String]!
    var images:[String]!
    var highlightImages:[String]!
    
    var selectionButton:UIButton!
    var selectionLabel:UILabel!
    
    var selectedIndex:Int = 0
    
    weak var delegate:CustomContextSheetDelegate?
    
    private var buttonsCollection = [UIButton]()
    private var labelsCollection = [UILabel]()
    private var centerXConstraints = [NSLayoutConstraint]()
    private var centerYConstraints = [NSLayoutConstraint]()
    
    private var isButtonPressed = false
    private var isAnimating = false
    
    private var maskLayer:CAShapeLayer!
    
    
    
    init(images:[String], highlightImages:[String]?, titles:[String]?) {
        //frame based on the constraints applied
        super.init(frame: CGRectZero)
        self.images = images
        self.highlightImages = highlightImages
        self.titles = titles
        self.setup()
    }

    init() {
        fatalError("init() has not been implemented")
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required internal init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: self.buttonSize, height: self.buttonSize)
    }
    
    private func setup() {
        self.buttonsCollection.removeAll(keepCapacity: false)
        self.labelsCollection.removeAll(keepCapacity: false)
        self.centerXConstraints.removeAll(keepCapacity: false)
        self.centerYConstraints.removeAll(keepCapacity: false)
        
        //selection button
        self.selectionButton = self.button(self.images[self.selectedIndex], highlightImage: nil, action: "toggleButtons")
        self.addSubview(self.selectionButton)
        
        //constraints
        self.addConstraints(self.centerAlignConstraints(self.selectionButton, retain: false))
        self.selectionButton.addConstraints(self.sizeConstraints(self.selectionButton, size: self.buttonSize))
        
        if self.titles != nil {
            //selected label
            self.selectionLabel = self.label(self.titles[self.selectedIndex])
            self.selectionLabel.alpha = 1
//            self.selectionLabel.backgroundColor = UIColor.redColor()
            self.insertSubview(self.selectionLabel, atIndex: 0)
            
            //constraints
            self.addConstraints(self.labelConstraints(self.selectionButton, itemB: self.selectionLabel))
        }
        
        
        //other buttons
        for i in 0...self.images.count-1 {
            
            let button = self.button(self.images[i], highlightImage: self.highlightImages?[i] ?? nil, action: "valueChanged:")
            button.hidden = true
            self.insertSubview(button, atIndex: 0)
            self.buttonsCollection.append(button)
            
            //centerXY constraints
            self.addConstraints(self.centerAlignConstraints(button, retain: true))
            
            //size constraints
            button.addConstraints(self.sizeConstraints(button, size: self.buttonSize))
            
            if self.titles != nil {
                //labels
                let label = self.label(self.titles[i])
                self.insertSubview(label, atIndex: 0)
                self.labelsCollection.append(label)
                
                //constraints
                self.addConstraints(self.labelConstraints(button, itemB: label))
            }
        }
    }
    
    func button(image:String, highlightImage:String?, action:Selector) -> UIButton {
        let button = UIButton(frame: CGRectZero)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.center = self.center
        button.setImage(UIImage(named: image), forState: UIControlState.Normal)
        if highlightImage != nil {
            button.setImage(UIImage(named: highlightImage!), forState: UIControlState.Highlighted)
        }
        button.layer.cornerRadius = self.buttonSize/2
        button.layer.masksToBounds = true
        button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }
    
    func centerAlignConstraints(item:UIButton, retain:Bool) -> [NSLayoutConstraint] {
        let centerXConstraint = NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)
        if retain {
            self.centerXConstraints.append(centerXConstraint)
            self.centerYConstraints.append(centerYConstraint)
        }
        return [centerXConstraint, centerYConstraint]
    }
    
    func sizeConstraints(item:UIButton, size:CGFloat) -> [NSLayoutConstraint] {
        let heightConstraint = NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: size)
        let widthConstraint = NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: size)
        return [heightConstraint, widthConstraint]
    }
    
    func label(title:String) -> UILabel {
        let label = UILabel(frame: CGRectZero)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.backgroundColor = UIColor.clearColor()
        label.attributedText = self.attributedText(title)
        label.alpha = 0
        label.sizeToFit()
        return label
    }
    
    func labelConstraints(itemA:UIButton, itemB:UILabel) -> [NSLayoutConstraint] {
        let horizontalSpacingConstraint = NSLayoutConstraint(item: itemA, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: itemB, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 10)
        let centerYConstraint = NSLayoutConstraint(item: itemA, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: itemB, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)
        return [horizontalSpacingConstraint, centerYConstraint]
    }
    
    func attributedText(title:String) -> NSAttributedString {
        let attributes = [NSStrokeWidthAttributeName: -3, NSStrokeColorAttributeName: UIColor.grayColor(), NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(18)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    //MARK: - Presentation logic
    
    private func showButtons() {
        if !self.isAnimating && !self.isButtonPressed {
            self.isAnimating = true
            
            //update the selection button to X
            self.selectionButton.setImage(UIImage(named: "LocationDisplayClose"), forState: UIControlState.Normal)
            //hide the selection label
            self.selectionLabel.attributedText = self.attributedText("Close")
            self.selectionLabel.sizeToFit()
            
            
            let animation = self.maskLayerAnimation(true)
            self.maskLayer.addAnimation(animation, forKey: animation.keyPath)
            
            self.buttonsCollection.map({$0.hidden = false})
            
            let constraints = self.centerYConstraints
            
            UIView.animateKeyframesWithDuration(self.animationDuration, delay: 0, options: UIViewKeyframeAnimationOptions.CalculationModeLinear, animations: { [weak self] () -> Void in
                if let weakSelf = self {
                    let count = constraints.count
                    for i in 0...count-1 {
                        UIView.addKeyframeWithRelativeStartTime(Double(i)/Double(count), relativeDuration: 1/Double(count), animations: { [weak self] () -> Void in
                            for j in i...count-1 {
                                let layout = constraints[j]
                                layout.constant -= weakSelf.buttonDisplacement
                            }
                            weakSelf.labelsCollection[i].alpha = 1
                            weakSelf.layoutIfNeeded()
                        })
                    }
                }
            }, completion: { [weak self] (finished:Bool) -> Void in
                self?.isAnimating = false
                self?.isButtonPressed = true
            })
            
        }
    }
    
    private func hideButtons() {
        if !self.isAnimating && self.isButtonPressed {
            self.isAnimating = true
            
            let animation = self.maskLayerAnimation(false)
            self.maskLayer.addAnimation(animation, forKey: animation.keyPath)
            
            let constraints = self.centerYConstraints
            
            UIView.animateKeyframesWithDuration(self.animationDuration, delay: 0, options: UIViewKeyframeAnimationOptions.CalculationModeLinear, animations: { [weak self] () -> Void in
                if let weakSelf = self {
                    let count = constraints.count
                    for i in 0...count-1 {
                        UIView.addKeyframeWithRelativeStartTime(Double(i)/Double(count), relativeDuration: 1/Double(count), animations: { [weak self] () -> Void in
                            for j in (count - 1 - i)...count-1 {
                                let layout = constraints[j]
                                layout.constant += weakSelf.buttonDisplacement
                            }
                            weakSelf.labelsCollection[count - 1 - i].alpha = 0
                            weakSelf.layoutIfNeeded()
                        })
                    }
                    
                }
            }, completion: { [weak self] (finished:Bool) -> Void in
                    self?.isAnimating = false
                    self?.isButtonPressed = false
                self?.buttonsCollection.map({$0.hidden = true})
                self?.updateSelectionButton(self!.selectedIndex)
            })
        }
    }
    
    func toggleButtons() {
        if self.isButtonPressed {
            self.hideButtons()
        }
        else {
            self.showButtons()
        }
    }
    
    func valueChanged(sender:UIButton) {
        //get index of sender
        if let index = find(self.buttonsCollection, sender) {
            self.selectedIndex = index
//            self.updateSelectionButton(index)
            //inform delegate
            self.delegate?.customContextSheet(self, didSelectItemAtIndex: index)
            self.toggleButtons()
        }
    }
    
    func updateSelectionButton(index:Int) {
        self.selectionButton.setImage(UIImage(named: self.images[index]), forState: .Normal)
        if self.titles != nil {
            self.selectionLabel.attributedText = self.attributedText(self.titles[index])
            self.selectionLabel.sizeToFit()
//            self.selectionLabel.hidden = false
        }
    }
    
    private func setupMaskLayer() {
        let screenFrame = UIScreen.mainScreen().bounds
        let x:CGFloat = max(frame.midX, screenFrame.size.width - frame.midX);
        let y:CGFloat = max(frame.midY, screenFrame.size.height - frame.midY);
        
        let radius = sqrt(x*x + y*y)
        self.maskLayer = CAShapeLayer()
        self.maskLayer.frame = CGRect(x: bounds.midX-radius, y: bounds.midY-radius, width: radius*2, height: radius*2)

        let path = CGPathCreateWithEllipseInRect(self.maskLayer.bounds, nil)
        self.maskLayer.path = path
        self.maskLayer.transform = CATransform3DMakeScale(0.0001, 0.0001, 0.0001)
        self.maskLayer.fillColor = UIColor(white: 0, alpha: 0.7).CGColor
        self.layer.insertSublayer(self.maskLayer, atIndex: 0)
    }
    
    private func maskLayerAnimation(fill:Bool) -> CABasicAnimation {
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.duration = self.animationDuration
        if fill {
            animation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(0.0001, 0.0001, 0.0001))
            animation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))
        }
        else {
            animation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))
            animation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(0.0001, 0.0001, 0.0001))
        }
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        return animation
    }
    
    //MARK: - 
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if self.isButtonPressed {
            return true
        }
        return super.pointInside(point, withEvent: event)
    }
    
    override func layoutSubviews() {
        if self.maskLayer == nil {
            self.setupMaskLayer()
        }
    }
}
