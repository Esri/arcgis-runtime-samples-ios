//
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
import ArcGIS

protocol IdentifyResultsVCDelegate:class {
    
    //method to notify the delegate that a selection was made
    func identifyResultsViewController(identifyResultsViewController:IdentifyResultsViewController, didSelectGeoElementAtIndex index:Int)
    
    //method to notify the delegate that the results view wasnts to hide/close
    func identifyResultsViewControllerWantsToClose(identifyResultsViewController:IdentifyResultsViewController)
}

class IdentifyResultsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIDynamicAnimatorDelegate {

    @IBOutlet var collectionView:UICollectionView!
    @IBOutlet var statusLabel:UILabel!
    @IBOutlet var forwardImageView:UIImageView!
    
    weak var delegate:IdentifyResultsVCDelegate?
    
    private var transitionSize:CGSize!
    private var transitionTrait:UITraitCollection!
    
    private var animator:UIDynamicAnimator!
    private var showAnimation = true
    
    var currentPage:Int = 0
    
    var geoElements = [AGSGeoElement]() {
        didSet {
            //update the status label
            self.statusLabel?.text = "1 of \(self.geoElements.count)"
            
            //reset collection view content offset
            if self.collectionView.contentOffset.x != 0 {
                self.collectionView.contentOffset.x = 0
            }
            
            //update the collection view
            self.collectionView?.reloadData()
            self.collectionView.layoutIfNeeded()
            
            //Show the bounce animation if not already shown and the geoElements are more than 1
            if self.geoElements.count > 1 && self.showAnimation {
                self.startBounceAnimation()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.geoElements.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ResultCell", forIndexPath: indexPath) as! GeoElementCell
        cell.geoElement = self.geoElements[indexPath.row]
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        //set the size of the cell the same as the size of the collection view
        return collectionView.bounds.size
    }
    
    //MARK: - Actions
    
    @IBAction func closeAction() {
        //notify the delegate to hide the results
        self.delegate?.identifyResultsViewControllerWantsToClose(self)
        
        //clear geoElements
        self.geoElements.removeAll()
        
        //update collection view
        self.collectionView.reloadData()
    }
    
    //MARK: - UIContentContainer protocol methods
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        //clear bounce animation
        self.clearBounceAnimation(true)
        
        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext) in
            self.collectionView.collectionViewLayout.invalidateLayout()
            if self.currentPage >= 1 {
                self.collectionView.contentOffset = CGPoint(x: CGFloat(self.currentPage-1)*self.collectionView.bounds.width, y: 0)
            }
            
        }) { (context:UIViewControllerTransitionCoordinatorContext) in
            
        }
    }
    
    //MARK: - UITraitEnvironment protocol methods
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.collectionView.collectionViewLayout.invalidateLayout()

    }
    
    //MARK: - Scrolling
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //calculate the current page based on content offset and collection view width
        let pageWidth = self.collectionView.bounds.width
        self.currentPage = Int(ceil(self.collectionView.contentOffset.x/pageWidth) + 1)
        
        //update the status label
        self.statusLabel.text = "\(currentPage) of \(self.geoElements.count)"
        
        //notify delegate
        self.delegate?.identifyResultsViewController(self, didSelectGeoElementAtIndex: currentPage-1)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        //reset cell
        self.clearBounceAnimation(true)
    }
    
    //MARK: - Dynamic Animator
    
    //add the bounce animation to the first cell of the collection view
    //to give a user the feedback that there are more results that can
    //be accessed by scrolling horizontally
    private func startBounceAnimation() {
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) {

            //unhide the arrow image laying underneath the cell
            self.forwardImageView.hidden = false
            
            //create an animator
            self.animator = UIDynamicAnimator(referenceView: self.collectionView)
            
            //get the custom dynamic behavior and add to the animator
            let customDynamicBehavior = self.customDynamicBehavior(cell)
            self.animator.addBehavior(customDynamicBehavior)
            
            //show the animation after a delay for smoothness
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                
                //apply a force to the cell to start the animation
                //PS: Assuming that the last child behavior is pushBehavior
                let forceX = weakSelf.collectionView.bounds.width/8
                let pushBehavior = weakSelf.animator.behaviors[0].childBehaviors.last as! UIPushBehavior
                
                pushBehavior.active = true
                pushBehavior.pushDirection = CGVector(dx: forceX, dy: 0)
                
                //assign self as the delegate for the animator
                //so that once the animation pauses, we can clear the animator
                weakSelf.animator.delegate = self
            })
        }
    }
    
    //clear the dynamic animator and also if required reset the cell frame
    private func clearBounceAnimation(resetCellFrame:Bool) {
        if self.animator != nil {
            //hide image view
            self.forwardImageView.hidden = true
            
            self.animator?.removeAllBehaviors()
            self.animator = nil
            
            if self.geoElements.count > 1 {
                self.showAnimation = false
            }
            
            if resetCellFrame {
                //reset cell
                if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) where cell.frame.origin != CGPointZero {
                    UIView.animateWithDuration(0.2, animations: {
                        cell.frame = CGRect(origin: CGPointZero, size: cell.frame.size)
                    })
                }
            }
        }
    }
    
    //custom behavior for the bounce animation on collection view cell
    private func customDynamicBehavior(cell: UICollectionViewCell) -> UIDynamicBehavior {
        let dynamicBehavior = UIDynamicBehavior()
        
        let collisionBehavior = UICollisionBehavior(items: [cell])
        collisionBehavior.setTranslatesReferenceBoundsIntoBoundaryWithInsets(UIEdgeInsets(top: 0, left: -200, bottom: 0, right: 0))
        dynamicBehavior.addChildBehavior(collisionBehavior)
        
        let gravityBehavior = UIGravityBehavior(items: [cell])
        gravityBehavior.gravityDirection = CGVector(dx: 1, dy: 0)
        dynamicBehavior.addChildBehavior(gravityBehavior)
        
        let itemBehavior = UIDynamicItemBehavior(items: [cell])
        itemBehavior.elasticity = 0.6
        dynamicBehavior.addChildBehavior(itemBehavior)
        
        let pushBehavior = UIPushBehavior(items: [cell], mode: .Instantaneous)
        pushBehavior.magnitude = 0
        pushBehavior.angle = 0
        dynamicBehavior.addChildBehavior(pushBehavior)
        
        return dynamicBehavior
    }
    
    //MARK: - UIDynamicAnimatorDelegate
    
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        //clear animation
        self.clearBounceAnimation(false)
    }
}
