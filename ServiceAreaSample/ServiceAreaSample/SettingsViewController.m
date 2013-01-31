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

@synthesize firstTimeBreak = _firstTimeBreak, secondTimeBreak = _secondTimeBreak;
@synthesize firstTimeBreakLabel = _firstTimeBreakLabel, secondTimeBreakLabel = _secondTimeBreakLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //initialize the default values. 
        _firstTimeBreak = 3;
        _secondTimeBreak = 8;
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

- (IBAction)firstTimeBreakChanged:(id)sender {    
    UISlider *firstTimeBreakSlider = (UISlider *) sender;
    _firstTimeBreak = firstTimeBreakSlider.value;
    self.firstTimeBreakLabel.text = [NSString stringWithFormat:@"%d", _firstTimeBreak];
}


- (IBAction)secondTimeBreakChanged:(id)sender {
    UISlider *secondTimeBreakSlider = (UISlider *) sender;
    _secondTimeBreak = secondTimeBreakSlider.value;
    self.secondTimeBreakLabel.text = [NSString stringWithFormat:@"%d", _secondTimeBreak];
  
}

- (IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end
