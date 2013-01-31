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
#import "DomainPickerViewController.h"


@class AGSPopup;
@class AttributeUtility;
@class DomainPickerViewController;
@class ClipboardViewController;

@protocol InspectionFormDelegate;

/*
 The Inspection form view controller is responsible for presenting a field of attributes
 for an inspection layer feature. The class will automatically fill in attributes that it
 can, and will also give the user a nice interface akin to a real form.  Further, the user
 will be a given a method to add an image attachment to the form if desired. The class
 could easily be extended to give the user the option of adding additional attachments
 */

@interface InspectionFormViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, 
                                                            DomainPickerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate,
                                                            UIPopoverControllerDelegate, UINavigationControllerDelegate>
{
    UIImageView *_paperImageView;
    UITableView *_tableView;
    UIButton *_takePictureButton;
    UIImageView *_stampImageView;
    UILabel *_leaseLabel;
    
    AGSPopup *_inspectionEditingPopup;
    AGSPopup *_featureToInspectPopup;
    NSMutableArray *_editableFieldInfos;
    
    NSDictionary *_originalFeatureAttributes;
    AttributeUtility *_attributeUtility;
    
    DomainPickerViewController *_domainPickerVC;
    
    id<InspectionFormDelegate> __weak _delegate;
    
    UIPopoverController *_imagePickerPopover;
    
    
    UIImage *_attachedImage;
    UIImageView *_paperClipImageView;
    UIImageView *_polaroidImageView;
    UIImageView *_polaroidContentImageView;
    BOOL _showingPolaroid;
}

/* Interface Builder Elements */
@property (nonatomic, strong) IBOutlet UIImageView *paperImageView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIButton *takePictureButton;
@property (nonatomic, strong) IBOutlet UIImageView *stampImageView;
@property (nonatomic, strong) IBOutlet UILabel *leaseLabel;

/* Popup References to the inspection we are creating, and the feature we are inspecting */
@property (nonatomic, strong) AGSPopup *inspectionEditingPopup;
@property (nonatomic, strong) AGSPopup *featureToInspectPopup;

@property (nonatomic, weak) id<InspectionFormDelegate> delegate;

/*An Image picker for adding an attachment */
@property (nonatomic, strong) UIPopoverController *imagePickerPopover;

@property (nonatomic, strong) NSMutableArray *editableFieldInfos;
@property (nonatomic, strong) NSDictionary *originalFeatureAttributes;
@property (nonatomic, strong) AttributeUtility *attributeUtility;

/*Domain picker for attribute fields that have a defined domain */
@property (nonatomic, strong) DomainPickerViewController *domainPickerVC;

/*Images for creating a cool attachment UI */
@property (nonatomic, strong) UIImage *attachedImage;
@property (nonatomic, strong) UIImageView *paperClipImageView;
@property (nonatomic, strong) UIImageView *polaroidImageView;
@property (nonatomic, strong) UIImageView *polaroidContentImageView;

/*Default initializer */
-(id)initWithInspectionPopup:(AGSPopup *)inspectionPopup andFeatureToInspectPopup:(AGSPopup *)toInspectPopup;

-(IBAction)cancelInspection;
-(IBAction)finishInspection;
-(IBAction)takePicture;

@end

@protocol InspectionFormDelegate <NSObject>

-(void)inspectionFormDidCancel:(InspectionFormViewController *)inspectionVC;
-(void)inspectionFormDidFinishWithNewInspection:(AGSPopup *)newInspectionPopup;

@end