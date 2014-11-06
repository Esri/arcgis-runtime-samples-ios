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

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@protocol OptionsViewControllerDelegate;

@interface OptionsViewController : UITableViewController

//array to store the list of options as NSString
@property (nonatomic, strong) NSArray *options;
//UITextField for which the options need to be displayed
@property (nonatomic, strong) UITextField *textField;

@property (weak, nonatomic) id <OptionsViewControllerDelegate> delegate;

@end

@protocol OptionsViewControllerDelegate <NSObject>

//delegate used to notify that an option was selected
-(void)optionsViewController:(OptionsViewController*)optionsViewController didSelectIndex:(NSInteger)index forTextField:(UITextField*)textField;

@end
