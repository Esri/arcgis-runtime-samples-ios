//
//  HorizontalPicker.swift
//  MapViewDemo-Swift
//
//  Created by Gagandeep Singh on 8/19/16.
//  Copyright © 2016 Esri. All rights reserved.
//

import UIKit

@IBDesignable
class HorizontalPicker: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var prevButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    
    private var nibView:UIView!
    
    var selectedIndex: Int = 0
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
        
        self.backgroundColor = UIColor.clearColor()
        
        self.nibView = self.loadViewFromNib()
        
        self.nibView.frame = self.bounds
        nibView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, .FlexibleWidth]
        
        self.addSubview(self.nibView)
        
        //collection view
        self.collectionView.registerClass(HorizontalPickerCell.self, forCellWithReuseIdentifier: "HorizontalPickerCell")
        
        self.setButtonsColor()
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "HorizontalPicker", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setButtonsColor() {
        let prevImage = self.prevButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        self.prevButton.imageView?.tintColor = self.buttonsColor
        self.prevButton.setImage(prevImage, forState: .Normal)
        
        let nextImage = self.nextButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        self.nextButton.imageView?.tintColor = self.buttonsColor
        self.nextButton.setImage(nextImage, forState: .Normal)
    }
    
    private func updateButtonsState() {
        let nextFlag = self.selectedIndex < self.options.count - 1
        self.nextButton.enabled = nextFlag
        self.nextButton.imageView?.tintColor = nextFlag ? self.buttonsColor : UIColor.grayColor()
        
        let prevFlag = self.selectedIndex > 0
        self.prevButton.enabled = prevFlag
        self.prevButton.imageView?.tintColor = prevFlag ? self.buttonsColor : UIColor.grayColor()
    }
    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.options?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HorizontalPickerCell", forIndexPath: indexPath) as! HorizontalPickerCell
        
        cell.titleLabel.text = self.options[indexPath.item]
        
        return cell
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return collectionView.bounds.size
    }
    
    //MARK: - UICollectionViewDelegate
    
    
    //MARK: - Layout subviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Scrolling
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.selectedIndex = Int(self.collectionView.contentOffset.x / self.collectionView.bounds.width)
        
        //update state of buttons
        self.updateButtonsState()
    }
    
    //MARK: - Actions
    
    @IBAction private func nextButtonAction() {
        if self.selectedIndex < self.options.count - 1 {
            //update selected index
            self.selectedIndex = self.selectedIndex + 1
            
            let indexPath = NSIndexPath(forItem: self.selectedIndex, inSection: 0)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
            
            //update state of buttons
            self.updateButtonsState()
        }
    }
    
    @IBAction private func prevButtonAction() {
        if self.selectedIndex > 0 {
            //update selected index
            self.selectedIndex = self.selectedIndex - 1
            
            let indexPath = NSIndexPath(forItem: self.selectedIndex, inSection: 0)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
            
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
        self.titleLabel.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.titleLabel.textAlignment = .Center
        
        self.contentView.addSubview(self.titleLabel)
    }
}
