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

@synthesize materialArray = _materialArray, parameterDic = _parameterDic;
@synthesize materialLabel = _materialLabel, timeSwitch = _timeSwitch, spillTypeSwitch = _spillTypeSwitch, materialPicker = _materialPicker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //initiating default paramenter dictionary
        self.parameterDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Anhydrous ammonia", @"Material_Type", @"Day", @"Day_or_Night_incident", @"Large", @"Large_or_Small_spill", nil];
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
    
    //start with the default material
    [self.materialPicker selectRow:0 inComponent:0 animated:YES];
    self.materialLabel.text = [_materialArray objectAtIndex:0];   
    
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
    [self.parameterDic setObject:[self.materialArray objectAtIndex:[self.materialPicker selectedRowInComponent:0]] forKey:@"Material_Type"];
}


#pragma mark Action Methods

- (IBAction)spillTypeChanged:(id)sender {
    if(self.spillTypeSwitch.selectedSegmentIndex == 0)
        [self.parameterDic setObject:@"Large" forKey:@"Large_or_Small_spill"];
    else
        [self.parameterDic setObject:@"Small" forKey:@"Large_or_Small_spill"];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)timeChanged:(id)sender {
    if(self.timeSwitch.selectedSegmentIndex == 0)
        [self.parameterDic setObject:@"Day" forKey:@"Day_or_Night_incident"];
    else
        [self.parameterDic setObject:@"Night" forKey:@"Day_or_Night_incident"];
}
@end
