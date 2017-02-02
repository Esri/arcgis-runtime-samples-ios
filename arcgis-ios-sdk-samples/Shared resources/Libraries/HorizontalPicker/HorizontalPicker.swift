//
//  HorizontalPicker.swift
//  MapViewDemo-Swift
//
//  Created by Gagandeep Singh on 8/19/16.
//  Copyright © 2016 Esri. All rights reserved.
//

import UIKit

@objc
protocol HorizontalPickerDelegate: class {
    
    @objc optional func horizontalPicker(_ horizontalPicker:HorizontalPicker, didUpdateSelectedIndex index: Int)
}

@IBDesignable
class HorizontalPicker: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var prevButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    
    private var nibView:UIView!
    
    weak var delegate: HorizontalPickerDelegate?
    
    var selectedIndex: Int = 0 {
        didSet {
            self.delegate?.horizontalPicker?(self, didUpdateSelectedIndex: selectedIndex)
        }
    }
    
    var options: [String]! {
        didSet {
            self.collectionView?.reloadData()
            self.updateButtonsState()
        }
    }
    var buttonsColor = UIColor(red: 0, green: 122/255.0, blue: 1, alpha: 1)
    
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
        self.collectionView.register(HorizontalPickerCell.self, forCellWithReuseIdentifier: "HorizontalPickerCell")
        
        self.setButtonsColor()
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "HorizontalPicker", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setButtonsColor() {
        let prevImage = self.prevButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        self.prevButton.imageView?.tintColor = self.buttonsColor
        self.prevButton.setImage(prevImage, for: UIControlState())
        
        let nextImage = self.nextButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        self.nextButton.imageView?.tintColor = self.buttonsColor
        self.nextButton.setImage(nextImage, for: UIControlState())
    }
    
    private func updateButtonsState() {
        let nextFlag = self.selectedIndex < self.options.count - 1
        self.nextButton.isEnabled = nextFlag
        self.nextButton.imageView?.tintColor = nextFlag ? self.buttonsColor : UIColor.gray
        
        let prevFlag = self.selectedIndex > 0
        self.prevButton.isEnabled = prevFlag
        self.prevButton.imageView?.tintColor = prevFlag ? self.buttonsColor : UIColor.gray
    }
    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.options?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HorizontalPickerCell", for: indexPath) as! HorizontalPickerCell
        
        cell.titleLabel.text = self.options[(indexPath as NSIndexPath).item]
        
        return cell
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return collectionView.bounds.size
    }
    
    //MARK: - UICollectionViewDelegate
    
    
    //MARK: - Layout subviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Scrolling
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.selectedIndex = Int(self.collectionView.contentOffset.x / self.collectionView.bounds.width)
        
        //update state of buttons
        self.updateButtonsState()
    }
    
    //MARK: - Actions
    
    @IBAction private func nextButtonAction() {
        if self.selectedIndex < self.options.count - 1 {
            //update selected index
            self.selectedIndex = self.selectedIndex + 1
            
            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
            
            //update state of buttons
            self.updateButtonsState()
        }
    }
    
    @IBAction private func prevButtonAction() {
        if self.selectedIndex > 0 {
            //update selected index
            self.selectedIndex = self.selectedIndex - 1
            
            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
            
            //update state of buttons
            self.updateButtonsState()
        }
    }
}


class HorizontalPickerCell: UICollectionViewCell {
    
    var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    func commonInit() {
        
        //initialize and add title label
        self.titleLabel = UILabel(frame: self.contentView.bounds)
        self.titleLabel.font = UIFont(name: "Avenir-Book", size: 17)
        self.titleLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.titleLabel.textAlignment = .center
        
        self.contentView.addSubview(self.titleLabel)
    }
}
