/*
 WIInspectionView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <ArcGIS/ArcGIS.h>
#import "WIInspectionView.h"
#import "WISignatureView.h"
#import "WISignatureLineView.h"
#import "AGSGeometry+Additions.h"
#import "WIAttributeUtility.h"
#import "WIInspectionFormCell.h"
#import "WIInspection.h"
#import "WIInspectionView.h"
#import "WIPinnedView.h"
#import "WIPolaroidView.h"

#define kCellOffsetTag 1000

@interface WIInspectionView () 

@property (nonatomic, strong) WIInspection         *inspection;
@property (nonatomic, strong) NSMutableDictionary   *originalFeatureAttributes;

@property (nonatomic, strong) UILabel               *formTitleLabel;
@property (nonatomic, strong) UITableView           *tableView;
@property (nonatomic, strong) WISignatureLineView  *signatureLineView;
@property (nonatomic, strong) UIButton              *cancelButton;
@property (nonatomic, strong) UIButton              *doneButton;
@property (nonatomic, strong) UIButton              *resetButton;
@property (nonatomic, strong) UIButton              *takePictureButton;
@property (nonatomic, strong) UIPopoverController   *imagePickerPopover;
@property (nonatomic, strong) WIPolaroidView       *polaroidView;

- (void)doneButtonPressed:(id)sender;
- (void)cancelButtonPressed:(id)sender;
- (void)resetButtonPressed:(id)sender;
- (void)takePictureButtonPressed:(id)sender;


- (void)enableFormElements:(BOOL)enable;

/* displays the polaroid of the selected image*/
- (void)showPolaroidOfImage:(UIImage *)image;

/* displays the photo picker so the user can add an image attachment */
- (void)showImagePickerWithType:(UIImagePickerControllerSourceType)sourceType; 

/* sets up our custom looking inspection sheet */
- (void)setupUxForFrame:(CGRect)frame;

/* retrieve an attribute's value for the given type */
- (id)getValueFromTextField:(UITextField *)textField forFeatureType:(AGSFieldType)fieldType;

@end

@implementation WIInspectionView

@synthesize delegate                    = _delegate;

@synthesize inspection                  = _inspection;
@synthesize originalFeatureAttributes   = _originalFeatureAttributes;

@synthesize formTitleLabel              = _formTitleLabel;
@synthesize tableView                   = _tableView;
@synthesize signatureLineView           = _signatureLineView;
@synthesize cancelButton                = _cancelButton;
@synthesize doneButton                  = _doneButton;
@synthesize resetButton                 = _resetButton;
@synthesize takePictureButton           = _takePictureButton;
@synthesize imagePickerPopover          = _imagePickerPopover;
@synthesize polaroidView                = _polaroidView;

- (void)dealloc
{
    [self.inspection.signatureView removeFromSuperview];
    

    
}


- (id)initWithFrame:(CGRect)frame withFeatureToInspect:(AGSPopup *)feature inspectionLayer:(AGSFeatureLayer *)inspectionLayer
{
    self = [self initWithFrame:frame];
    if(self)
    {    
        WIInspection *i = [[WIInspection alloc] initWithFeatureToInspect:feature inspectionLayer:inspectionLayer];
        self.inspection = i;
        
        //save original attributes in case they decide to cancel
        self.originalFeatureAttributes = [[self.inspection.popup.graphic allAttributes] mutableCopy];
         
        // setup our custom look and feel
        [self setupUxForFrame:frame];
    }
    
    return self;
}

//Editing a previous inspection
- (id)initWithFrame:(CGRect)frame inspection:(WIInspection *)inspection
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.inspection = inspection;
        
        //save original attributes in case they decide to cancel
        self.originalFeatureAttributes = [[self.inspection.popup.graphic allAttributes] mutableCopy];
        
        // setup our custom look and feel
        [self setupUxForFrame:frame];
    }
    
    return self;
}

- (void)setupUxForFrame:(CGRect)frame
{
    // this gives us the yellow paper background
    self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper_texture.png"]];
    
    CGFloat titleMargin = 5.0f;
    CGFloat titleHeight = 40.0f;
    UILabel *formTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleMargin, frame.size.width, titleHeight)];
    formTitleLabel.textAlignment = UITextAlignmentCenter;
    formTitleLabel.font = [UIFont fontWithName:@"Courier" size:25.0];
    formTitleLabel.backgroundColor = [UIColor clearColor];
    formTitleLabel.text = @"Inspection Form";
    
    self.formTitleLabel = formTitleLabel;
    
    //Tableview
    CGFloat tableYOrigin = 2*titleMargin + titleHeight;
    CGFloat tableHeight = 450.0f;
    CGFloat tableMargin = 20.0f;
    CGFloat tableWidth = frame.size.width - 2*tableMargin;
    CGRect tvRect = CGRectMake(tableMargin, tableYOrigin, tableWidth, tableHeight);
    UITableView *tv = [[UITableView alloc] initWithFrame:tvRect style:UITableViewStylePlain];
    tv.dataSource = self;
    tv.delegate = self;
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tv.backgroundColor = [UIColor clearColor];
    self.tableView = tv;
    
    //Signature View
    CGRect sigRect = CGRectMake(tableMargin, tableYOrigin + tableHeight + 5, tvRect.size.width, 190);
    self.inspection.signatureView.frame = sigRect;
    
    //Line for Signature
    WISignatureLineView *lineView = [[WISignatureLineView alloc] initWithFrame:sigRect];
    self.signatureLineView = lineView;
    
    //Buttons
    CGFloat margin          = 5.0f;
    CGFloat buttonWidth     = 40.0f;
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.takePictureButton.frame = CGRectMake(margin, margin, 64.0, 40.0);
    [self.takePictureButton setImage:[UIImage imageNamed:@"camera_line_drawing.png"] forState:UIControlStateNormal];
    [self.takePictureButton addTarget:self action:@selector(takePictureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(frame.size.width - (margin + buttonWidth), margin, buttonWidth, buttonWidth);
    self.doneButton.alpha = 0.7f;
    [self.doneButton setImage:[UIImage imageNamed:@"checkmark.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.frame = CGRectMake(self.doneButton.frame.origin.x - (buttonWidth + 2*margin), margin, buttonWidth, buttonWidth);
    self.cancelButton.alpha = 0.7f;
    [self.cancelButton setImage:[UIImage imageNamed:@"cancelButton.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect rectOfX = self.signatureLineView.xRect;
    self.resetButton.frame = CGRectMake(sigRect.origin.x + rectOfX.origin.x, sigRect.origin.y + rectOfX.origin.y, rectOfX.size.width, rectOfX.size.height);
    [self.resetButton addTarget:self action:@selector(resetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.formTitleLabel];
    [self addSubview:self.tableView];
    [self addSubview:self.signatureLineView];
    [self addSubview:self.inspection.signatureView];
    [self addSubview:self.cancelButton];
    [self addSubview:self.doneButton];
    [self addSubview:self.resetButton];
    [self addSubview:self.takePictureButton];
    
    // if this inspection has any images, show the first one in our polaroid view
    if(self.inspection.images.count > 0)
    {
        [self showPolaroidOfImage:[self.inspection.images objectAtIndex:0]];
    }
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.inspection.editableFieldInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    WIInspectionFormCell *cell = (WIInspectionFormCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[WIInspectionFormCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    AGSPopupFieldInfo *fi = [self.inspection.editableFieldInfos objectAtIndex:indexPath.row];
    AGSField *field = [self.inspection.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    
    cell.fieldName.text = fi.label;
    cell.fieldResult.text  = [self.inspection.attributeUtility attributeStringForField:field];
    
    //set tag on text field so we can get a handle on it later
    cell.fieldResult.tag = indexPath.row + kCellOffsetTag;
    cell.fieldResult.delegate = self;  
    
    return cell;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    int tag = textField.tag - kCellOffsetTag;
    
    AGSPopupFieldInfo *fi = [self.inspection.editableFieldInfos objectAtIndex:tag];
    AGSField *field = [self.inspection.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    if ([self.inspection.attributeUtility isAStringField:field]) {
        return YES;
    }
    else if([self.inspection.attributeUtility isANumberField:field])
    {
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        return YES;
    }
    //don't want *anything* to happen with a date field
    else if([self.inspection.attributeUtility isADateField:field])
    {
        return NO;
    }
    
    CGRect domainRect = CGRectMake(50, 100, 500, 300);
    WIDomainPickerView *dpv = [[WIDomainPickerView alloc] initWithFrame:domainRect 
                                                           withInspection:self.inspection 
                                                          fieldOfInterest:fi];
    dpv.selectedValue = [self.inspection.popup.graphic attributeForKey:fi.fieldName];
    dpv.delegate = self;
    
    WIPinnedView *pv = [[WIPinnedView alloc] initWithContentView:dpv 
                                                       leftPinType:AGSPinnedViewTypeTape 
                                                      rightPinType:AGSPinnedViewTypeNone];
    
    [self addSubview:pv];
    
    //disable rest of form while picking a domain
    [self enableFormElements:NO];
    
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self textFieldDidEndEditing:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    int tag = textField.tag - kCellOffsetTag;
    
    //get fieldInfo for tag
    AGSPopupFieldInfo * fi = [self.inspection.editableFieldInfos objectAtIndex:tag];
    
    AGSField *field = [self.inspection.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    //if we directly edited the text field, we either have a number or a string
    if ([self.inspection.attributeUtility isAStringField:field]) {
        NSString *text = (textField.text && textField.text.length > 0) ? textField.text : @"";
        
        [self.inspection.popup.graphic setAttribute:text forKey:fi.fieldName];
    }
    else if([self.inspection.attributeUtility isANumberField:field])
    {
        id numValue = [self getValueFromTextField:textField forFeatureType:field.type];
        
        [self.inspection.popup.graphic setAttribute:numValue forKey:fi.fieldName];
    }
    
    [textField resignFirstResponder];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark AGSDomainPickerViewDelegate

- (void)domainPickerViewDidFinish:(WIDomainPickerView *)dpv
{
    if (self.inspection.attributeUtility.featureLayer){
		if ([dpv.fieldOfInterest.fieldName isEqualToString:self.inspection.attributeUtility.featureLayer.typeIdField]){
			if (![dpv.selectedValue isEqual:[self.inspection.popup.graphic attributeForKey:dpv.fieldOfInterest.fieldName]]){
                
				// change values based on new template chosen
				AGSFeatureLayer *fl = self.inspection.attributeUtility.featureLayer;
				AGSFeatureTemplate *t = dpv.templateChosen;
				AGSGraphic *p = t.prototype;
				AGSGraphic *g = self.inspection.popup.graphic;
				for (NSString *fieldName in [[p allAttributes] allKeys]){
                    
					[g setAttribute: [p attributeForKey:fieldName]  forKey:fieldName];
				}
				// Update popupUtility.featureType
				for (AGSFeatureType *type in fl.types){
					if ([type.templates containsObject:t]){
						self.inspection.attributeUtility.featureType = type;
					}
				}
			}
		}
	}
    
    [self.inspection.popup.graphic setAttribute:dpv.selectedValue  forKey:dpv.fieldOfInterest.fieldName];
    
    //Update Ux
    [self.tableView reloadData];
    [self enableFormElements:YES];
    
    //Domain picker was housed in pin view.. Get of rid of that. The domain picker will autorelease itself
    [dpv.superview removeFromSuperview];
}

#pragma mark -
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //take photo
    if (buttonIndex == 0) {
        [self showImagePickerWithType:UIImagePickerControllerSourceTypeCamera];
    }
    //Choose existing photo
    else {
        [self showImagePickerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

#pragma mark -
#pragma mark Image Picker and Related Methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image == nil) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //add image to inspection
    [self.inspection.images addObject:image];
    
    //kill popover
    [self.imagePickerPopover dismissPopoverAnimated:YES];
    self.imagePickerPopover = nil;
    
    //finally show image
    [self showPolaroidOfImage:image]; 
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePickerPopover = nil;
}

#pragma mark -
#pragma mark Button Interactions
- (void)doneButtonPressed:(id)sender
{    
    self.inspection.dateModified = [NSDate date];
    
    if([self.delegate respondsToSelector:@selector(inspectionView:didFinishWithInspection:)])
    {
        [self.delegate inspectionView:self didFinishWithInspection:self.inspection];
    }
}

- (void)cancelButtonPressed:(id)sender
{
    [self.inspection.popup.graphic setAllAttributes: self.originalFeatureAttributes];
    
    if ([self.delegate respondsToSelector:@selector(inspectionView:didCancelCollectingInspection:)]) {
        [self.delegate inspectionView:self didCancelCollectingInspection:self.inspection];
    }
}

- (void)resetButtonPressed:(id)sender
{
    [self.inspection.signatureView reset];
}

- (void)takePictureButtonPressed:(id)sender
{
    //sample only allows adding one image
    if(self.inspection.images.count > 0)
    {
        return;
    }
    
    BOOL bIsCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (bIsCameraAvailable)
    {
        //we have a camera, so let the user pick between that and the saved photo roll
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                 delegate:self 
                                                         cancelButtonTitle:nil 
                                                    destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Choose Existing Photo", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        actionSheet.delegate = self;
        [actionSheet showFromRect:self.takePictureButton.frame inView:self animated:YES];
    }
    else {
        [self showImagePickerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
    }  	
}

#pragma mark -
#pragma mark private
- (id)getValueFromTextField:(UITextField *)textField forFeatureType:(AGSFieldType)fieldType
{
    id value = nil;
    
    if (fieldType == AGSFieldTypeSmallInteger)
    {
        value = [NSNumber numberWithInt:[textField.text intValue]];
    }
    else if (fieldType == AGSFieldTypeInteger)
    {
        value = [NSNumber numberWithInt:[textField.text intValue]];
    }
    else if (fieldType == AGSFieldTypeSingle)
    {
        value = [NSNumber numberWithFloat:[textField.text floatValue]];
    }
    else if (fieldType == AGSFieldTypeDouble)
    {
        NSScanner *scanner = [NSScanner scannerWithString:textField.text];
        
        double doubleVal;
        [scanner scanDouble:&doubleVal];
        value = [NSNumber numberWithDouble:doubleVal];
    }
    
    return value;
}

//Disable inspectionf form elements when views are overlayed over the form itself (like a domain picker)
- (void)enableFormElements:(BOOL)enable
{
    self.tableView.userInteractionEnabled = enable;
    self.doneButton.userInteractionEnabled = enable;
    self.cancelButton.userInteractionEnabled = enable;
}

- (void)showPolaroidOfImage:(UIImage *)image
{    
    if(self.polaroidView == nil)
    {
        // create our polaroid view, only if it didn't already exist
        WIPolaroidView *pv = [[WIPolaroidView alloc] initWithOrigin:CGPointMake(-365, 340) withImage:image];
        self.polaroidView = pv;
    }
    
    [self addSubview:self.polaroidView];

    // let our photo "develop"
    [self.polaroidView processPolaroidAnimated:YES];
}

- (void)showImagePickerWithType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.allowsEditing = YES;
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    imagePicker.delegate = self;
    
    self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
    self.imagePickerPopover.delegate = self;
    [self.imagePickerPopover presentPopoverFromRect:self.takePictureButton.frame 
                                             inView:self 
                           permittedArrowDirections:UIPopoverArrowDirectionAny 
                                           animated:YES]; 
}

@end
