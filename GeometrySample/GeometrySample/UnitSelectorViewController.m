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

#import "UnitSelectorViewController.h"
#import <ArcGIS/ArcGIS.h>

@implementation UnitSelectorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    
    // Create the data sources for the table view with the different unit options
    self.distanceUnits = [NSArray arrayWithObjects:[NSNumber numberWithInt:AGSSRUnitSurveyMile], [NSNumber numberWithInt:AGSSRUnitSurveyYard], [NSNumber numberWithInt:AGSSRUnitSurveyFoot], [NSNumber numberWithInt:AGSSRUnitKilometer],[NSNumber numberWithInt:AGSSRUnitMeter], nil];
    
    self.areaUnits = [NSArray arrayWithObjects:[NSNumber numberWithInt:AGSAreaUnitsSquareMiles], [NSNumber numberWithInt:AGSAreaUnitsAcres],[NSNumber numberWithInt:AGSAreaUnitsSquareYards], [NSNumber numberWithInt: AGSAreaUnitsSquareKilometers], [NSNumber numberWithInt:AGSAreaUnitsSquareMeters], nil];
                          

    self.tableView.delegate = self; 
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor grayColor];

}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // When a row is tapped call the delegate method to update the units
    if (!self.useAreaUnits) {
        [self.delegate didSelectDistanceUnit:[[self.distanceUnits objectAtIndex:indexPath.row] intValue]];
    }
    else {
        [self.delegate didSelectAreaUnit:[[self.areaUnits objectAtIndex:indexPath.row] intValue]];
    }
    
    return;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCustomCellID = @"MyCellID";
	
    // Create a cell
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomCellID];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomCellID];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    // Set the text according to the unit option
    if (!self.useAreaUnits) {
        
        AGSSRUnit currentUnit = [[self.distanceUnits objectAtIndex:indexPath.row] intValue];
        
        switch (currentUnit) {
            case AGSSRUnitSurveyMile:
                cell.textLabel.text = @"Miles";
                break;
            case AGSSRUnitSurveyYard:
                cell.textLabel.text = @"Yards";
                break;
            case AGSSRUnitSurveyFoot:
                cell.textLabel.text = @"Feet";
                break;
            case AGSSRUnitKilometer:
                cell.textLabel.text = @"Kilometers";
                break;
            case AGSSRUnitMeter:
                cell.textLabel.text = @"Meters";
                break;
            default:
                break;
        }
    }
    else {
        AGSAreaUnits currentUnit = [[self.areaUnits objectAtIndex:indexPath.row] intValue];
        
        switch (currentUnit) {
            case AGSAreaUnitsSquareMiles:
                cell.textLabel.text = @"Square Miles";
                break;
            case AGSAreaUnitsAcres:
                cell.textLabel.text = @"Acres";
                break;
            case AGSAreaUnitsSquareYards:
                cell.textLabel.text = @"Square Yards";
                break;
            case AGSAreaUnitsSquareKilometers:
                cell.textLabel.text = @"Square Kilometers";
                break;
            case AGSAreaUnitsSquareMeters:
                cell.textLabel.text = @"Square Meters";
            default:
                break;
        }
    }
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return 5 one for each unit option
    return 5;
}


- (void)viewDidUnload
{
    self.tableView = nil;
    self.distanceUnits = nil;
    self.areaUnits = nil;
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
