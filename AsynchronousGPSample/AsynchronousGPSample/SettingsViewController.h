// Copyright 2011 ESRI
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


@interface SettingsViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource> {
    
    UILabel *_materialLabel;
    UISegmentedControl *_timeSwitch;
    UISegmentedControl *_spillTypeSwitch;
    UIPickerView *_materialPicker;
    
    NSMutableArray *_materialArray;
    NSMutableDictionary *_parameterDic;
    

}

@property (nonatomic, strong) NSMutableArray* materialArray;
@property (nonatomic, strong) NSMutableDictionary *parameterDic;

@property (nonatomic, strong) IBOutlet UILabel *materialLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *timeSwitch;
@property (nonatomic, strong) IBOutlet UISegmentedControl *spillTypeSwitch;
@property (nonatomic, strong) IBOutlet UIPickerView *materialPicker;


- (IBAction)timeChanged:(id)sender;
- (IBAction)spillTypeChanged:(id)sender;
- (IBAction)done:(id)sender;


@end
