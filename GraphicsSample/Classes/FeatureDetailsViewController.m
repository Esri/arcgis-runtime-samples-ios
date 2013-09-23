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

#import "FeatureDetailsViewController.h"


@implementation FeatureDetailsViewController

@synthesize detailsTable, feature, displayFieldName;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated {
    self.title = [feature attributeAsStringForKey:displayFieldName];
    [self.detailsTable reloadData];
}



//get the attributes
- (void)setFeature:(AGSGraphic *)f {
    feature = f;
    
    
    NSDictionary *theDict = [feature allAttributes];
    NSArray *allKeys = [theDict allKeys];
    keys = allKeys;
    aliases = (NSMutableArray*)keys;
}

//get the field aliases
- (void)setFieldAliases:(NSDictionary *)fa {
    if (keys) {

        aliases = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (NSString *key in keys) {
            [aliases addObject:[fa valueForKey:key]];
        }
    }
}


#pragma mark -
#pragma mark UITableViewDataSource

//the section in the table is as large as the number of attributes the feature has
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (keys) {
        return [keys count];
    }
    
    return 0;
}

//called by table view when it needs to draw one of its rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//static instance to represent a single kind of cell. Used if the table has cells formatted differently
    static NSString *FeatureDetailsViewControllerCellIdentifier = @"FeatureDetailsViewControllerCellIdentifier";
    
	//as cells roll off screen get the reusable cell, if we can't create a new one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeatureDetailsViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:FeatureDetailsViewControllerCellIdentifier];
    }
    
	//extract the attribute and its value and display both in the cell
    NSUInteger row = [indexPath row];
    cell.textLabel.text = [aliases objectAtIndex:row];
    
    NSString *key = [keys objectAtIndex:row];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [feature attributeAsStringForKey:key]];

    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate


@end
