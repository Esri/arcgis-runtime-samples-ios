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

@property (nonatomic, strong) AGSServiceFeatureTable *featureTable;
@property (nonatomic, strong) AGSQueryParameters *query;
@property (nonatomic, strong) AGSFeatureQueryResult *featureQueryResult;
@property (nonatomic, strong) DetailsViewController *detailsViewController;

@end



@implementation RootViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	//title for the navigation controller
    self.title = kViewTitle;
	//text in search bar before user enters in query
	self.searchBar.placeholder = kSearchBarPlaceholder;
	NSString *countiesLayerURL = kMapServiceLayerURL;
	
	//set up feature table against layer
	self.featureTable = [AGSServiceFeatureTable serviceFeatureTableWithURL:[NSURL URLWithString:countiesLayerURL]];
	
	//set query params
	self.query = [AGSQueryParameters queryParameters];
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
    if (nil == self.featureQueryResult) {
		return 0;
	}
	
	return [self.featureQueryResult.featureEnumerator.allObjects count];
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
	AGSFeature *feature = [self.featureQueryResult.featureEnumerator.allObjects objectAtIndex:indexPath.row];
	cell.textLabel.text = feature.attributes[@"NAME"]; //The display field name for the service we are using
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

//when a user selects a row (i.e. cell) in the table display all the selected features
//attributes in a separate view controller
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//if view controller not created, create it, set up the field names to display
	if (nil == self.detailsViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
		self.detailsViewController = [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewController"];
		self.detailsViewController.fields = self.featureQueryResult.fields;
		self.detailsViewController.displayFieldName = @"NAME";
	}
	
	//the details view controller needs to know about the selected feature to get its value
	self.detailsViewController.feature = [self.featureQueryResult.featureEnumerator.allObjects objectAtIndex:indexPath.row];
	
	//display the feature attributes
	[self.navigationController pushViewController:self.detailsViewController animated:YES];
}




#pragma mark UISearchBarDelegate

//when the user searches
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	//display busy indicator, get search string and execute query
    __weak __typeof(self) weakSelf = self;
    self.query.whereClause = [NSString stringWithFormat:@"NAME = '%@'",searchBar.text];
	[self.featureTable queryFeaturesWithParameters:self.query fields:AGSQueryFeatureFieldsLoadAll completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            [weakSelf queryFailedWithError:error];
        }
        else {
            [weakSelf queryFinishedWithResult:result];
        }
    }];
	
	[searchBar resignFirstResponder];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[searchBar resignFirstResponder];
}


#pragma mark AGSQueryTaskDelegate

//results are returned
- (void)queryFinishedWithResult:(AGSFeatureQueryResult*)featureQueryResult {
	//get feature, and load in to table
	self.featureQueryResult = featureQueryResult;
	[super.tableView reloadData];
}

//if there's an error with the query display it to the user
- (void)queryFailedWithError:(NSError *)error {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}


@end

