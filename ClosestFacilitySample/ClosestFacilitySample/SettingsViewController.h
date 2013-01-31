// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UIViewController {
    
    
    NSUInteger _facilityCount;
    NSUInteger _cutoffTime;
    
    UILabel *_facilityCountLabel;
    UILabel *_cutoffTimeLabel;
}

@property (nonatomic, readonly) NSUInteger facilityCount;
@property (nonatomic, readonly) NSUInteger cutoffTime;
@property (nonatomic, strong) IBOutlet UILabel *facilityCountLabel;
@property (nonatomic, strong) IBOutlet UILabel *cutoffTimeLabel;

- (IBAction)facilityCountChanged:(id)sender;
- (IBAction)cutoffTimeChanged:(id)sender;
- (IBAction)done:(id)sender;


@end
