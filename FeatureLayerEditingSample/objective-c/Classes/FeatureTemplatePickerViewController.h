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

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
@class FeatureTemplatePickerViewController;

/** The delegate that will be notified by FeatureTemplatePickerViewController
 when the user dismisses the controller or picks a template from the list 
 */
@protocol FeatureTemplatePickerDelegate <NSObject>

@optional

-(void)featureTemplatePickerViewControllerWasDismissed: (FeatureTemplatePickerViewController*) featureTemplatePickerViewController;

-(void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController*) featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate*)template forFeatureLayer:(AGSFeatureLayer*)featureLayer;

@end


@interface FeatureTemplatePickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate> {
	UITableView* _featureTemplatesTableView;
    id<FeatureTemplatePickerDelegate> __weak _delegate;
    NSMutableArray* _infos;
}

@property (nonatomic, weak) id<FeatureTemplatePickerDelegate> delegate;
@property (nonatomic,strong) IBOutlet UITableView* featureTemplatesTableView;
@property (nonatomic, strong) NSMutableArray* infos;



- (IBAction) dismiss;
- (void) addTemplatesFromLayer:(AGSFeatureLayer*)layer;

@end


/** A value object to hold information about the feature type, template and layer */
@interface FeatureTemplatePickerInfo : NSObject {
@private
    AGSFeatureType* __weak _featureType;
    AGSFeatureTemplate* __weak _featureTemplate;
    AGSFeatureLayer* __weak _featureLayer;
}

@property (nonatomic, weak) AGSFeatureType* featureType;
@property (nonatomic, weak) AGSFeatureTemplate* featureTemplate;
@property (nonatomic, weak) AGSFeatureLayer* featureLayer;

@end

