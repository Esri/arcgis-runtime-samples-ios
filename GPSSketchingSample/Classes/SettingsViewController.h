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

// Keys for the dictionary provided to the delegate.
extern NSString * const kSetupInfoKeyAccuracy;
extern NSString * const kSetupInfoKeyDistanceFilter;


@class SettingsViewController;

@protocol SettingsViewControllerDelegate <NSObject>

@required
- (void)didFinishWithSettings;
@end


@interface SettingsViewController : UIViewController
{
    id <SettingsViewControllerDelegate> __weak delegate;
}

@property (nonatomic, weak) id <SettingsViewControllerDelegate> delegate;

//dictionary containing settings. 
@property (nonatomic, strong) NSMutableDictionary *setupInfo;


@end
