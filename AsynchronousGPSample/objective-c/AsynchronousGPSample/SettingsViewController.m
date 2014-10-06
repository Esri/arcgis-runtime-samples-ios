
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

#import "SettingsViewController.h"


@implementation SettingsViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        //do some intialization
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
    
    self.materialArray = [NSMutableArray array];
    
    [self.materialArray addObject:@"Anhydrous ammonia"];
    [self.materialArray addObject:@"Boron trifluoride"];
    [self.materialArray addObject:@"Carbon monoxide"];
    [self.materialArray addObject:@"Chlorine"];
    [self.materialArray addObject:@"Coal gas"];
    [self.materialArray addObject:@"Cyanogen"];
    [self.materialArray addObject:@"Ethylene oxide"];
    [self.materialArray addObject:@"Fluorine"];
    [self.materialArray addObject:@"Hydrogen sulphide"];
    [self.materialArray addObject:@"Methyl bromide"];
    
    //update view to show selected material
    [self.materialPicker selectRow:[self.materialArray indexOfObject:self.parameters.materialType] inComponent:0 animated:YES];
    self.materialLabel.text = self.parameters.materialType;
    
    //reflect the current selections
    self.timeSwitch.selectedSegmentIndex = [self.parameters.dayOrNightIncident isEqualToString:@"Day"] ? 0 : 1;
    self.spillTypeSwitch.selectedSegmentIndex = [self.parameters.largeOrSmallSpill isEqualToString:@"Large"] ? 0 : 1;
    
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

#pragma mark UIPickerDelegate Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    //only the material type.
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    //the number of matarials in the array. 
    return [self.materialArray count];
}


- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.materialArray objectAtIndex:row];
}


- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {    
    self.materialLabel.text = [self.materialArray objectAtIndex:row];
    self.parameters.materialType = [self.materialArray objectAtIndex:row];
}


#pragma mark Action Methods

- (IBAction)spillTypeChanged:(id)sender {
    if(self.spillTypeSwitch.selectedSegmentIndex == 0)
        self.parameters.largeOrSmallSpill = @"Large";
    else
        self.parameters.largeOrSmallSpill = @"Small";
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)timeChanged:(id)sender {
    if(self.timeSwitch.selectedSegmentIndex == 0)
        self.parameters.dayOrNightIncident = @"Day";
    else
        self.parameters.dayOrNightIncident = @"Night";
}
@end
