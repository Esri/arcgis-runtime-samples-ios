/*
 WIPinchableContainerView.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <UIKit/UIKit.h>

@protocol WIPinchableContainerViewDelegate;

@interface WIPinchableContainerView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, unsafe_unretained) id<WIPinchableContainerViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) UIView *activeView;

- (void)addListView:(UIView*)listView;
- (void)removeListView:(UIView*)listView;
- (void)animateBack;
- (void)animateOut;
@end

@protocol WIPinchableContainerViewDelegate <NSObject>

- (void)pinchView:(WIPinchableContainerView*)pinchView pinchingWithScale:(CGFloat)scale;
- (void)pinchViewWillAnimateBack:(WIPinchableContainerView *)pinchView;
- (void)pinchViewDidAnimateBack:(WIPinchableContainerView *)pinchView;
- (void)pinchViewDidAnimateOut:(WIPinchableContainerView *)pinchView;

@end
