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

#import "RootViewController.h"


@interface RootViewController ()

@property (nonatomic, strong) AGSQueryTask *queryTask;
@property (nonatomic, strong) AGSQuery *query;
@property (nonatomic, strong) AGSFeatureSet *featureSet;
@property (nonatomic, strong) DetailsViewController *detailsViewController;

@end



@implementation RootViewController

@synthesize searchBar = _searchBar;
@synthesize queryTask = _queryTask, query = _query, featureSet = _featureSet, detailsViewController = _detailsViewController;


- (void)viewDidLoad {
    [super viewDidLoad];

	//title for the navigation controller
    self.title = kViewTitle;
	//text in search bar before user enters in query
	self.searchBar.placeholder = kSearchBarPlaceholder;
	NSString *countiesLayerURL = kMapServiceLayerURL;
	
	//set up query task against layer, specify the delegate
	self.queryTask = [AGSQueryTask queryTaskWithURL:[NSURL URLWithString:countiesLayerURL]];
	self.queryTask.delegate = self;
	
	//return all fields in query 
	self.query = [AGSQuery query];
	self.query.outFields = [NSArray arrayWithObjects:@"*", nil];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

//one section in this table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//the section in the table is as large as the number of fetaures returned from the query
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (nil == self.featureSet) {
		return 0;
	}
	
	return [self.featureSet.features count];
}

//called by table view when it needs to draw one of its rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	//static instance to represent a single kind of cell. Used if the table has cells formatted differently
    static NSString *RootViewControllerCellIdentifier = @"RootViewControllerCellIdentifier";
    
	//as cells roll off screen get the reusable cell, if we can't create a new one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RootViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RootViewControllerCellIdentifier];
    }
	
    //get selected feature and extract the name attribute
	//display name in cell
	//add detail disclosure button. This will allow user to see all the attributes in a different view
	AGSGraphic *feature = [self.featureSet.features objectAtIndex:indexPath.row];
	cell.textLabel.text = [feature attributeAsStringForKey:@"NAME"]; //The display field name for the service we are using
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

//when a user selects a row (i.e. cell) in the table display all the selected features
//attributes in a separate view controller
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//if view controller not created, create it, set up the field names to display
	if (nil == self.detailsViewController) {
		self.detailsViewController = [[DetailsViewController alloc] initWithNibName:@"DetailsView" bundle:nil];
		self.detailsViewController.fieldAliases = self.featureSet.fieldAliases;
		self.detailsViewController.displayFieldName = self.featureSet.displayFieldName;
	}
	
	//the details view controller needs to know about the selected feature to get its value
	self.detailsViewController.feature = [self.featureSet.features objectAtIndex:indexPath.row];
	
	//display the feature attributes
	[self.navigationController pushViewController:self.detailsViewController animated:YES];
}




#pragma mark UISearchBarDelegate

//when the user searches
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	//display busy indicator, get search string and execute query
	self.query.text = searchBar.text;
	[self.queryTask executeWithQuery:self.query];
	
	[searchBar resignFirstResponder];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[searchBar resignFirstResponder];
}


#pragma mark AGSQueryTaskDelegate

//results are returned
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet {
	//get feature, and load in to table
	self.featureSet = featureSet;
	[super.tableView reloadData];
}

//if there's an error with the query display it to the user
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}


@end

