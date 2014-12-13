/*
 Copyright 2014 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "LayersListViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "OptionsViewController.h"

#define POPOVER_WIDTH 200
#define POPOVER_HEIGHT 200

@interface LayersListViewController () <UITableViewDataSource, UITableViewDelegate, OptionsDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, strong) NSMutableArray *deletedLayerInfos;
@property (nonatomic, strong) OptionsViewController *optionsViewController;
@property (nonatomic, strong) UIPopoverController *popover;

@end

@implementation LayersListViewController

-(void)setLayerInfos:(NSMutableArray *)layerInfos {
    _layerInfos = layerInfos;
    
    //initialize the deleted infos array if done already
    if (!self.deletedLayerInfos) {
        self.deletedLayerInfos = [NSMutableArray arrayWithCapacity:layerInfos.count];
    }
    //relaod the table view to reflect the layer info changes
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //initialize the optionsViewController
    self.optionsViewController = [[OptionsViewController alloc] initWithStyle:UITableViewStylePlain];
    self.optionsViewController.delegate = self;
    
    //initialize the popover controller
    self.popover = [[UIPopoverController alloc] initWithContentViewController:self.optionsViewController];
    self.popover.popoverContentSize = CGSizeMake(POPOVER_WIDTH, POPOVER_HEIGHT);
    
    //enable editing on tableview
    [self.tableView setEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - table view datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.layerInfos.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"LayersListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];

    AGSLayerInfo *layerInfo = [self.layerInfos objectAtIndex:indexPath.row];
    cell.textLabel.text = layerInfo.name;
    //enable reordering on each cell
    [cell setShowsReorderControl:YES];
    return cell;
}

//enable re ordering on each row
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - table view delegates

//update the order of layer infos in the array
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    //get the layer info being moved
    AGSDynamicLayerInfo *layerInfo = [self.layerInfos objectAtIndex:sourceIndexPath.row];
    //remove the layerInfo from the previous index
    [self.layerInfos removeObjectAtIndex:sourceIndexPath.row];
    //add the layer info at the new index
    [self.layerInfos insertObject:layerInfo atIndex:destinationIndexPath.row];
    //notify the delegate to update the dynamic service layer
    [self updateDynamicServiceLayer];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    //check if the editing style is Delete
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //save the object in the deleted layer infos array
        AGSLayerInfo *layerInfo = [self.layerInfos objectAtIndex:indexPath.row];
        [self.deletedLayerInfos addObject:layerInfo];
        //remove the layer info from the data source array
        [self.layerInfos removeObjectAtIndex:indexPath.row];
        //delete the row
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        //update dynamic service
        [self updateDynamicServiceLayer];
        //update the add button status
        [self updateAddButtonStatus];
    }
    else {
        NSLog(@"Editing style other than delete");
    }
}

#pragma mark - 

//the method creates an array of AGSDynamicLayerInfo from the array of AGSLayerInfo
//the AGSDynamicLayerInfo array can be assigned to the AGSDynamicMapService to update
//the ordering or add or delete a layer
-(NSArray*)createDynamicLayerInfos:(NSArray*)layerInfos {
    //instantiate a new mutable array
    NSMutableArray *dynamicLayerInfos = [[NSMutableArray alloc] initWithCapacity:layerInfos.count];
    //loop through the layer infos array and create a corresponding
    //dynamic layer info
    for (AGSLayerInfo *layerInfo in layerInfos) {
        AGSDynamicLayerInfo *dynamicLayerInfo = [[AGSDynamicLayerInfo alloc] initWithLayerID:layerInfo.layerId];
        [dynamicLayerInfos addObject:dynamicLayerInfo];
    }
    return dynamicLayerInfos;
}

//the method notifies the delegate about the changes in the layerInfos
-(void)updateDynamicServiceLayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(layersListViewController:didUpdateLayerInfos:)]) {
        //create dynamic layer infos from the layer infos
        NSArray *dynamicLayerInfos = [self createDynamicLayerInfos:self.layerInfos];
        //notify the delegate
        [self.delegate layersListViewController:self didUpdateLayerInfos:dynamicLayerInfos];
    }
}

//this method enables/disables the Add bar button item based on the
//count of values in the deletedLayerInfos array
-(void)updateAddButtonStatus {
    self.addButton.enabled = self.deletedLayerInfos.count > 0 ? YES : NO;
}

#pragma mark - Actions

- (IBAction)addAction:(UIBarButtonItem*)sender {
    //update the options array with the current layerInfos array
    self.optionsViewController.options = self.deletedLayerInfos;
    //present the popover controller
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark - OptionsDelegate

-(void)optionsViewController:(OptionsViewController *)optionsViewController didSelectOption:(id)option {
    //hide the popover controller
    [self.popover dismissPopoverAnimated:YES];
    //remove the layer info from deleted layer Infos
    [self.deletedLayerInfos removeObject:option];
    //and add it to the layer infos
    [self.layerInfos insertObject:option atIndex:0];
    //reload tableview
    [self.tableView reloadData];
    //notify the delegate to update the dynamic service
    [self updateDynamicServiceLayer];
    //update the status of the add button
    [self updateAddButtonStatus];
}

@end
