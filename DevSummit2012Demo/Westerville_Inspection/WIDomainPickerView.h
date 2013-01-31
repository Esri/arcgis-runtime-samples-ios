/*
 WIDomainPickerView.h
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
#import "WIIndexCardTableView.h"

@class WIInspection;
@class AGSPopupFieldInfo;
@protocol WIDomainPickerViewDelegate;
@class AGSFeatureTemplate;

/*
 Index card that will allow a user to pick a value from a domain.
 */

@interface WIDomainPickerView : UIView <WIIndexCardTableViewDataSource, WIIndexCardTableViewDelegate, UITableViewDelegate>

/* Value selected by the domain picker */
@property (nonatomic, strong) id                                selectedValue;

/* Field representing the domain, subtype, etc  */
@property (nonatomic, strong) AGSPopupFieldInfo                 *fieldOfInterest;

/* Delegate  */
@property (nonatomic, unsafe_unretained) id<WIDomainPickerViewDelegate>   delegate;

/* Chosen template */
@property (nonatomic, strong, readonly) AGSFeatureTemplate      *templateChosen;

- (id)initWithFrame:(CGRect)frame withInspection:(WIInspection *)inspection fieldOfInterest:(AGSPopupFieldInfo *)fieldInfo;

@end

@protocol WIDomainPickerViewDelegate <NSObject>

@required
- (void)domainPickerViewDidFinish:(WIDomainPickerView *)dpv;

@end
