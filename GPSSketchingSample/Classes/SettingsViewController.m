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

//constants to be used for the keys. 
NSString * const kSetupInfoKeyAccuracy = @"SetupInfoKeyAccuracy";
NSString * const kSetupInfoKeyDistanceFilter = @"SetupInfoKeyDistanceFilter";


@interface SettingsViewController()

//used for setting the frequency distance in meters for the location updates. 
@property (nonatomic, strong) IBOutlet UISegmentedControl *frequencyControl;

//used for setting the accuracy in meters for the location updates. 
@property (nonatomic, strong) IBOutlet UISegmentedControl *accuracyControl;



//dismisses the settings view controller. 
- (IBAction)done:(id)sender;

@end

@implementation SettingsViewController

@synthesize delegate;
@synthesize frequencyControl = _frequencyControl;
@synthesize accuracyControl = _accuracyControl;
@synthesize setupInfo = _setupInfo;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        //setup the dictionary. 
        self.setupInfo = [NSMutableDictionary dictionary];
        [self.setupInfo setObject:[NSNumber numberWithDouble:1.0] forKey:kSetupInfoKeyDistanceFilter]; 
        [self.setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters] forKey:kSetupInfoKeyAccuracy];

    }
    return self;}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set the state of the outlets. 
    self.frequencyControl.selectedSegmentIndex = 0;
    self.accuracyControl.selectedSegmentIndex = 0;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)done:(id)sender 
{ 
    [self dismissViewControllerAnimated:YES completion:nil];
    [delegate didFinishWithSettings];   
}

- (IBAction)controlChanged:(id)sender
{
    //set the appropriate value in the settings dict according to the selection. 
    if(sender == self.frequencyControl)
    {
        switch (self.frequencyControl.selectedSegmentIndex) {
            case 0:
                [self.setupInfo setObject:[NSNumber numberWithDouble:1.0] forKey:kSetupInfoKeyDistanceFilter];
                break;
            case 1:
                [self.setupInfo setObject:[NSNumber numberWithDouble:10.0] forKey:kSetupInfoKeyDistanceFilter];
                break;
            case 2:
                [self.setupInfo setObject:[NSNumber numberWithDouble:100.0] forKey:kSetupInfoKeyDistanceFilter];
                break;
            case 3:
                [self.setupInfo setObject:[NSNumber numberWithDouble:1000.0] forKey:kSetupInfoKeyDistanceFilter];
                break;
                
            default:
                break;
        }
    }
    
    //set the appropriate value in the settings dict according to the selection. 
    if(sender == self.accuracyControl)
    {
        switch (self.accuracyControl.selectedSegmentIndex) {
            case 0:
                 [self.setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyBest] forKey:kSetupInfoKeyAccuracy];
                break;
            case 1:
                [self.setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters] forKey:kSetupInfoKeyDistanceFilter];
                break;
            case 2:
                [self.setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters] forKey:kSetupInfoKeyDistanceFilter];
                break;
            case 3:
                [self.setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyKilometer] forKey:kSetupInfoKeyDistanceFilter];
                break;
                
            default:
                break;
        }

    }
}

- (void)dealloc {
	self.delegate = nil;
}


@end
