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
    
    
    NSUInteger _firstTimeBreak;
    NSUInteger _secondTimeBreak;
    
    UILabel *_firstTimeBreakLabel;
    UILabel *_secondTimeBreakLabel;
}

@property (nonatomic, readonly) NSUInteger firstTimeBreak;
@property (nonatomic, readonly) NSUInteger secondTimeBreak;
@property (nonatomic, strong) IBOutlet UILabel *firstTimeBreakLabel;
@property (nonatomic, strong) IBOutlet UILabel *secondTimeBreakLabel;

- (IBAction)firstTimeBreakChanged:(id)sender;
- (IBAction)secondTimeBreakChanged:(id)sender;
- (IBAction)done:(id)sender;


@end
