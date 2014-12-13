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

@interface FeatureDetailsViewController ()

@property (nonatomic, strong) NSArray *keys;
@property (nonatomic, strong) NSMutableArray *aliases;

@end

@implementation FeatureDetailsViewController

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
    self.title = [self.feature attributeAsStringForKey:self.displayFieldName];
    [self.detailsTable reloadData];
}



//set the attributes
- (void)setFeature:(AGSGraphic *)f {
    _feature = f;
    
    
    NSDictionary *theDict = [self.feature allAttributes];
    NSArray *allKeys = [theDict allKeys];
    self.keys = allKeys;
    self.aliases = (NSMutableArray*)self.keys;
}

//set the field aliases
- (void)setFieldAliases:(NSDictionary *)fa {
    if (self.keys) {

        self.aliases = [[NSMutableArray alloc] initWithCapacity:[self.keys count]];
        for (NSString *key in self.keys) {
            [self.aliases addObject:[fa valueForKey:key]];
        }
    }
}


#pragma mark -
#pragma mark UITableViewDataSource

//the section in the table is as large as the number of attributes the feature has
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.keys) {
        return [self.keys count];
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
    cell.textLabel.text = [self.aliases objectAtIndex:row];
    
    NSString *key = [self.keys objectAtIndex:row];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.feature attributeAsStringForKey:key]];

    return cell;
}


#pragma mark -
#pragma mark actions

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
