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

@class AGSPopupFieldInfo;
@class AttributeUtility;
@class AGSFeatureTemplate;
@protocol DomainPickerDelegate;

@interface DomainPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> 
{
    UIImageView *_postItNoteImageView;
    UITableView *_tableView;
    
    id _value;
    
    id<DomainPickerDelegate> __weak _delegate;
    
    AGSPopupFieldInfo *_fieldInfo;
    AttributeUtility *_attributeUtility;
    
    // when editing subtype field
	NSMutableArray *_templateTypeValues;
	NSMutableArray *_templates;
	AGSFeatureTemplate *_templateChosen;
}

/*Interface builder elements */
@property (nonatomic, strong) IBOutlet UIImageView *postItNoteImageView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet AGSPopupFieldInfo *fieldInfo;
@property (nonatomic, strong) IBOutlet AttributeUtility *attributeUtility;

@property (nonatomic, strong) id value;

@property (nonatomic, weak) id<DomainPickerDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *templates;
@property (nonatomic, strong) NSMutableArray *templateTypeValues;
@property (nonatomic, strong) AGSFeatureTemplate *templateChosen;

/*Default initializer */
-(id)initWithFieldInfo:(AGSPopupFieldInfo *)fi andAttributeUtility:(AttributeUtility *)attributeUtility;

-(IBAction)doneButtonPressed;

@end

@protocol DomainPickerDelegate <NSObject>

-(void)domainPickerDidFinish:(DomainPickerViewController *)dpvc;

@end

