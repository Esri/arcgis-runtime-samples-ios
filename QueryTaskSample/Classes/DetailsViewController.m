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

#import "DetailsViewController.h"


@interface DetailsViewController ()

@property (nonatomic, strong) NSArray *aliases;

@end



@implementation DetailsViewController

@synthesize feature = _feature, fieldAliases = _fieldAliases, displayFieldName = _displayFieldName;
@synthesize aliases = _aliases;


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


//get the field aliases
- (void)setFieldAliases:(NSDictionary *)fieldAliases {
	_fieldAliases = fieldAliases;
	
	self.aliases = [self.fieldAliases allKeys];
}

//load the table wiht feature attributes
- (void)setFeature:(AGSGraphic *)feature {
	_feature = feature;
	self.title = [feature attributeAsStringForKey:self.displayFieldName];
	
	[super.tableView reloadData];
}


#pragma mark Table view methods

//one section in this table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


//the section in the table is as large as the number of attributes the feature has
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (nil == self.feature) {
		return 0;
	}
	
    return [self.aliases count];
}


//called by table view when it needs to draw one of its rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//static instance to represent a single kind of cell. Used if the table has cells formatted differently
    static NSString *DetailsViewControllerCellIdentifier = @"DetailsViewControllerCellIdentifier";
    
	//as cells roll off screen get the reusable cell, if we can't create a new one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DetailsViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DetailsViewControllerCellIdentifier];
    }
    
	//extract the attribute and its value and display both in the cell
    NSString *key = [self.aliases objectAtIndex:indexPath.row];
	cell.textLabel.text = [self.fieldAliases valueForKey:key];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.feature attributeAsStringForKey:key]];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


- (void)dealloc {
    self.feature = nil;
    self.fieldAliases = nil;
	
}


@end

