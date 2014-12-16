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
#import "Parameters.h"

@interface SettingsViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *facilityCountLabel;
@property (nonatomic, strong) IBOutlet UILabel *cutoffTimeLabel;
@property (nonatomic, strong) Parameters *parameters;

@property (weak, nonatomic) IBOutlet UISlider *facilityCountSlider;
@property (weak, nonatomic) IBOutlet UISlider *cutOffTimeSlider;

- (IBAction)facilityCountChanged:(id)sender;
- (IBAction)cutoffTimeChanged:(id)sender;
- (IBAction)done:(id)sender;


@end
