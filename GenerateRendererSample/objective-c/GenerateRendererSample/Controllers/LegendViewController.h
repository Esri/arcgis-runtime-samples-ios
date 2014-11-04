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
#import "OptionsViewController.h"

@protocol LegendViewControllerDelegate;

@interface LegendViewController : UIViewController <OptionsViewControllerDelegate>

//array to store the AGSFields of the feature layer
@property (nonatomic, strong) NSArray *classificationFields;
//delegate
@property (weak, nonatomic) id <LegendViewControllerDelegate> delegate;

//method used to get the name of the currently selected classificationField
//used to display the information in the callout
-(NSString*)selectedFieldName;

@end

@protocol LegendViewControllerDelegate <NSObject>

//notifies the delegate that the renderer was generated successfully
-(void)legendViewController:(LegendViewController*)legendViewController didGenerateRenderer:(AGSRenderer*)renderer;
//notifies the delegate it failed to generate renderer with the error
-(void)legendViewController:(LegendViewController*)legendViewController failedToGenerateRendererWithError:(NSError*)error;
@end
