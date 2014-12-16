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

#import "OptionsViewController.h"
#import <ArcGIS/ArcGIS.h>

@interface OptionsViewController ()

@end

@implementation OptionsViewController

#pragma mark - setter methods

-(void)setOptions:(NSArray *)options {
    _options = options;
    //reload the tableview every time options is assigned a value
    [self.tableView reloadData];
}

#pragma mark - View Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //change background color to transparent
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.options.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableIdentifier = @"OptionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableIdentifier];
    }
    AGSLayerInfo *layerInfo = [self.options objectAtIndex:indexPath.row];
    cell.textLabel.text = layerInfo.name;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

#pragma mark - table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //notify the delegate about the selection
    if (self.delegate && [self.delegate respondsToSelector:@selector(optionsViewController:didSelectOption:)]) {
        AGSLayerInfo *layerInfo = [self.options objectAtIndex:indexPath.row];
        [self.delegate optionsViewController:self didSelectOption:layerInfo];
    }
}

@end
