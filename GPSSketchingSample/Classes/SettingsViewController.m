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

#import "SettingsViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface SettingsViewController()

//used for setting the frequency distance in meters for the location updates. 
@property (nonatomic, strong) IBOutlet UISegmentedControl *frequencyControl;

//used for setting the accuracy in meters for the location updates. 
@property (nonatomic, strong) IBOutlet UISegmentedControl *accuracyControl;

//used to store the possible values for accuracy and freqeuncy
@property (nonatomic, strong) NSArray *accuracyValues, *frequencyValues;


//dismisses the settings view controller. 
- (IBAction)done:(id)sender;

@end

@implementation SettingsViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accuracyValues = @[[NSNumber numberWithDouble:kCLLocationAccuracyBest], [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters], [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters], [NSNumber numberWithDouble:kCLLocationAccuracyKilometer]];
    self.frequencyValues = @[[NSNumber numberWithDouble:1.0], [NSNumber numberWithDouble:10.0], [NSNumber numberWithDouble:100.0], [NSNumber numberWithDouble:1000.0]];
    
    //update segment control selection based on the parameter object
    [self.accuracyControl setSelectedSegmentIndex:[self.accuracyValues indexOfObject:self.parameters.accuracyValue]];
    [self.frequencyControl setSelectedSegmentIndex:[self.frequencyValues indexOfObject:self.parameters.frequencyValue]];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)done:(id)sender 
{ 
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)controlChanged:(id)sender
{
    //set the appropriate value in the settings dict according to the selection. 
    if(sender == self.frequencyControl)
    {
        self.parameters.frequencyValue = [self.frequencyValues objectAtIndex:[self.frequencyControl selectedSegmentIndex]];
    }
    
    //set the appropriate value in the settings dict according to the selection. 
    if(sender == self.accuracyControl)
    {
        self.parameters.accuracyValue = [self.accuracyValues objectAtIndex:[self.accuracyControl selectedSegmentIndex]];

    }
}

@end
