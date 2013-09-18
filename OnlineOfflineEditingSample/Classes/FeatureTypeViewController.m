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

#import "FeatureTypeViewController.h"
#import "CodedValueUtility.h"

@implementation FeatureTypeViewController

@synthesize featureLayer = _featureLayer;
@synthesize feature = _feature;
@synthesize completedDelegate = _completedDelegate;

#pragma mark -
#pragma mark View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.title = @"Choose Species";
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	// if the layer does not have subtypes
	if (self.featureLayer.templates.count > 0){
		return self.featureLayer.templates.count;
	}
	
	// if the layer has subtypes
	int count = 0;
	for (AGSFeatureType *ft in self.featureLayer.types){
		count += ft.templates.count;
	}
	
    return count;
}

-(AGSFeatureTemplate*)templateForIndex:(int)index{
	
	//
	//  this function will find the appropriate template
	// as if they were all flattened out into a single list
	//
	
	
	// if the feature layer just has a list of templates
	if (self.featureLayer.templates.count > 0){
		return [self.featureLayer.templates objectAtIndex:index];
	}
	
	// if the feature layer has subtypes
	else {
		int i = 0;
		for (AGSFeatureType *ft in self.featureLayer.types){
			for (int j=0; j<ft.templates.count; j++){
				if (i == index){
					return [ft.templates objectAtIndex:j];
				}
				i++;
			}
		}
	}
	
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
    // Set up the cell...
	// find the appropriate template
	AGSFeatureTemplate *template = [self templateForIndex:indexPath.row];
	
	// once we have the template, we can set the text and the image
	AGSGraphic *proto = [[AGSGraphic alloc]initWithGeometry:nil symbol:nil attributes:template.prototypeAttributes];
	cell.textLabel.text = template.name;
	cell.imageView.image = [self.featureLayer.renderer swatchForFeature:proto geometryType:self.featureLayer.geometryType size:CGSizeMake(20, 20)];
	
    return cell;
}


/*
 // Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// find the template and set the attributes on the feature to the tempalte's prototype attributes
	AGSFeatureTemplate *template = [self templateForIndex:indexPath.row];
    
    //create the feature here
	self.feature = [self.featureLayer featureWithTemplate:template];
    
    if (self.completedDelegate && [self.completedDelegate respondsToSelector:@selector(didSelectFeatureType:)])
    {
        [self.completedDelegate performSelector:@selector(didSelectFeatureType:) withObject:self];
    }
    
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	self.featureLayer = nil;
	self.feature = nil;
    self.completedDelegate = nil;
    [super dealloc];
}


@end

