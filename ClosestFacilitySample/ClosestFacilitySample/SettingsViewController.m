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
    
    //reflect default values in sliders
    self.facilityCountSlider.value = [self.parameters.facilityCount intValue];
    self.facilityCountLabel.text = [NSString stringWithFormat:@"%@", self.parameters.facilityCount];
    
    self.cutOffTimeSlider.value = [self.parameters.cutoffTime intValue];
    self.cutoffTimeLabel.text = [NSString stringWithFormat:@"%@", self.parameters.cutoffTime];
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
    self.parameters.facilityCount = [NSNumber numberWithInt:facilityCountSlider.value];
    self.facilityCountLabel.text = [NSString stringWithFormat:@"%@", self.parameters.facilityCount];
}


- (IBAction)cutoffTimeChanged:(id)sender {
    UISlider *cutoffTimeSlider = (UISlider *) sender;
    self.parameters.cutoffTime = [NSNumber numberWithInt:cutoffTimeSlider.value];
    self.cutoffTimeLabel.text = [NSString stringWithFormat:@"%@", self.parameters.cutoffTime];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
