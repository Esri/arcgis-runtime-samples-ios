//
//  HorizontalColorPicker.swift
//  MapViewDemo-Swift
//
//  Created by Gagandeep Singh on 8/19/16.
//  Copyright © 2016 Esri. All rights reserved.
//

import UIKit

@objc
protocol HorizontalColorPickerDelegate: class {
    @objc optional func horizontalColorPicker(_ horizontalColorPicker:HorizontalColorPicker, didUpdateSelectedIndex index: Int)
}

@IBDesignable
class HorizontalColorPicker: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet private var collectionView: UICollectionView!
    
    private var nibView:UIView!
    private var onlyOnce = true
    private var colors : [UIColor] = HorizontalColorPicker.someColors()

    weak var delegate: HorizontalColorPickerDelegate?
    
    var selectedColor : UIColor?
    var selectedIndex: Int = 0 {
        didSet {
            //
            // Fire delegate
            self.delegate?.horizontalColorPicker?(self, didUpdateSelectedIndex: selectedIndex)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
        
        self.nibView = self.loadViewFromNib()
        self.nibView.frame = self.bounds
        nibView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, .flexibleWidth]
        self.addSubview(self.nibView)
        
        //collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 25, height: 25)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        self.collectionView.collectionViewLayout = layout
        self.collectionView.register(HorizontalColorPickerCell.self, forCellWithReuseIdentifier: "HorizontalColorPickerCell")
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "HorizontalColorPicker", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HorizontalColorPickerCell", for: indexPath) as! HorizontalColorPickerCell
        cell.color = colors[indexPath.row]
        return cell
    }
    
    //scroll to an item at start up
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if self.onlyOnce {
            self.onlyOnce = false
            
            self.collectionView.layoutIfNeeded()
            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .right, animated: false)
        }
    }
    
    //MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedColor = colors[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.selectedColor = nil
    }
    
    //MARK: - Layout subviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Helper Function
    
    private static func someColors() -> [UIColor]{
        
        var colors = [UIColor]()
        
        let hSteps = 10
        let hStart = CGFloat(0.0)
        let hStepVal = (1.0 - hStart) / CGFloat(hSteps)
        
        let bSteps = 10
        let bStart = CGFloat(0.25)
        let bStepVal = (1.0 - bStart) / CGFloat(bSteps)
        
        let sSteps = 1
        let sStart = CGFloat(0.5)
        let sStepVal = (1.0 - sStart) / CGFloat(sSteps)
        
        for h in 0 ..< hSteps{
            
            // Color order: red, pink, purple, blue, green, orange
            let hVal = 1.0 - (hStepVal * CGFloat(h))
            
            for s in 0 ..< sSteps{
                let sVal = 1.0 - (sStepVal * CGFloat(s))
                
                for b in 0 ..< bSteps{
                    let bVal = 1.0 - (bStepVal * CGFloat(b))
                    colors.append(UIColor(hue: hVal, saturation: sVal, brightness: bVal, alpha: 1.0))
                }
            }
        }
        return colors
    }
}


class HorizontalColorPickerCell: UICollectionViewCell {
    
    var colorView : UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        //
        // Initialize and add color view
        self.colorView = UIView(frame: self.contentView.bounds)
        self.colorView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.contentView.addSubview(self.colorView)
    }
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
                self.colorView.frame = contentView.bounds.insetBy(dx: 3, dy: 3)
                layer.borderColor = UIColor.darkGray.cgColor
                layer.borderWidth = 1.0
            }
            else{
                self.colorView.frame = contentView.bounds
                layer.borderColor = nil
                layer.borderWidth = 0.0
            }
        }
    }
    
    var color : UIColor?{
        didSet{
            self.colorView.backgroundColor = color
        }
    }
}
