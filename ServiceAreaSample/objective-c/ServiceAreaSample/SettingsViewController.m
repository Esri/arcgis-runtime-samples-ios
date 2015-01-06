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

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //assign values to the segment controls based on the parameters value
    [self.firstTimeBreakSlider setValue:self.parameters.firstTimeBreak animated:YES];
    self.firstTimeBreakLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.parameters.firstTimeBreak];
    [self.secondTimeBreakSlider setValue:self.parameters.secondTimeBreak animated:YES];
    self.secondTimeBreakLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.parameters.secondTimeBreak];
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

- (IBAction)firstTimeBreakChanged:(id)sender {    
    UISlider *firstTimeBreakSlider = (UISlider *) sender;
    self.parameters.firstTimeBreak = firstTimeBreakSlider.value;
    self.firstTimeBreakLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)firstTimeBreakSlider.value];
}


- (IBAction)secondTimeBreakChanged:(id)sender {
    UISlider *secondTimeBreakSlider = (UISlider *) sender;
    self.parameters.secondTimeBreak = secondTimeBreakSlider.value;
    self.secondTimeBreakLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)secondTimeBreakSlider.value];
  
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
