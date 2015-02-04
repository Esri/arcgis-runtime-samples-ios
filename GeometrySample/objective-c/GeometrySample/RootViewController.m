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

#import "RootViewController.h"
#import "BufferViewController.h"
#import "CutterViewController.h"
#import "DensifyViewController.h"
#import "UnionDifferenceViewController.h"
#import "OffsetViewController.h"
#import "ProjectViewController.h"
#import "RelationshipViewController.h"
#import "MeasureViewController.h"

#define kBufferViewControllerIdentifier @"BufferViewController"
#define kCutterViewControllerIdentifier @"CutterViewController"
#define kDensifyViewControllerIdentifier @"DensifyViewController"
#define kUnionDifferenceViewControllerIdentifier @"UnionDifferenceViewController"
#define kOffsetViewControllerIdentifier @"OffsetViewController"
#define kProjectViewControllerIdentifier @"ProjectViewController"
#define kRelationshipViewControllerIdentifier @"RelationshipViewController"
#define kMeasureViewControllerIdentifier @"MeasureViewController"

@implementation RootViewController

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
    // Eight sections, one for each detail view controller.
    return 8;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"RootViewControllerCellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Set appropriate labels for the cells.
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Buffer";
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"Cut";
    }
    else if(indexPath.row ==2) {
        cell.textLabel.text = @"Densify";
    }
    else if(indexPath.row == 3) {
        cell.textLabel.text = @"Union & Difference";
    }
    else if(indexPath.row == 4) {
         cell.textLabel.text = @"Offset";
    }
    else if (indexPath.row == 5) {
        cell.textLabel.text = @"Project";
    }
    else if (indexPath.row == 6) {
        cell.textLabel.text = @"Spatial Relationships";
    }
    else {
        cell.textLabel.text = @"Measure";
    }

    return cell;
}


#pragma mark -
#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = indexPath.row;
    
    //Obtain an instance of storyboard to create an object of the desired view controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    NSString *desiredViewControllerIdentifier;
    
    // Create and configure a new detail view controller appropriate for the selection.
    UIViewController *detailViewController = nil;

    if (row == 0) {
        desiredViewControllerIdentifier = kBufferViewControllerIdentifier;
    }
    else if (row == 1) {
        desiredViewControllerIdentifier = kCutterViewControllerIdentifier;
    }
    else if (row == 2) {
        desiredViewControllerIdentifier = kDensifyViewControllerIdentifier;
    }
    else if (row == 3) {
        desiredViewControllerIdentifier = kUnionDifferenceViewControllerIdentifier;
    }
    else if (row == 4) {
        desiredViewControllerIdentifier = kOffsetViewControllerIdentifier;
    }
    else if (row == 5) {
        desiredViewControllerIdentifier = kProjectViewControllerIdentifier;
    }
    else if (row == 6) {
        desiredViewControllerIdentifier = kRelationshipViewControllerIdentifier;
    }
    else {
        desiredViewControllerIdentifier = kMeasureViewControllerIdentifier;
    }
    
    //instantiate the desired view controller
    detailViewController = [storyboard instantiateViewControllerWithIdentifier:desiredViewControllerIdentifier];
    
    // Update the split view controller's view controllers array.
    UISplitViewController *splitViewController = [self.navigationController splitViewController];
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, detailViewController, nil];
    splitViewController.viewControllers = viewControllers;
    
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.title = @"Operations";
}

#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Memory management

@end
