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


@implementation SettingsViewController

@synthesize facilityCount = _facilityCount, cutoffTime = _cutoffTime;
@synthesize facilityCountLabel = _facilityCountLabel, cutoffTimeLabel = _cutoffTimeLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //do any initiation here if needed. 
        _facilityCount = 3;
        _cutoffTime = 10;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark Action Methods

- (IBAction)facilityCountChanged:(id)sender {    
    UISlider *facilityCountSlider = (UISlider *) sender;
    _facilityCount = facilityCountSlider.value;
    self.facilityCountLabel.text = [NSString stringWithFormat:@"%d", _facilityCount];
}


- (IBAction)cutoffTimeChanged:(id)sender {
    UISlider *cutoffTimeSlider = (UISlider *) sender;
    _cutoffTime = cutoffTimeSlider.value;
    self.cutoffTimeLabel.text = [NSString stringWithFormat:@"%d", _cutoffTime];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
