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

#import "InspectionFormViewController.h"
#import "InspectionFormTableViewCell.h"
#import "AttributeUtility.h"
#import "DomainPickerViewController.h"
#import <ArcGIS/ArcGIS.h>

//private methods
@interface InspectionFormViewController () 

-(id)getValueFromTextField:(UITextField *)textField forFeatureType:(AGSFieldType)fieldType;
-(void)showPolaroidOfImage:(UIImage *)image;
-(void)showImagePickerWithType:(UIImagePickerControllerSourceType)sourceType;  

@end

#define kCellOffsetTag 1000
#define kMaxSizeString 11
#define kPolaroidRotationAngle .055
#define kPolaroidDevelopmentTime 3

@implementation InspectionFormViewController

@synthesize paperImageView = _paperImageView;
@synthesize tableView = _tableView;
@synthesize takePictureButton = _takePictureButton;
@synthesize stampImageView = _stampImageView;
@synthesize leaseLabel = _leaseLabel;
@synthesize inspectionEditingPopup = _inspectionEditingPopup;
@synthesize featureToInspectPopup = _featureToInspectPopup;
@synthesize delegate = _delegate;
@synthesize originalFeatureAttributes = _originalFeatureAttributes;
@synthesize editableFieldInfos = _editableFieldInfos;
@synthesize attributeUtility = _attributeUtility;
@synthesize domainPickerVC = _domainPickerVC;
@synthesize attachedImage = _attachedImage;
@synthesize paperClipImageView = _paperClipImageView;
@synthesize polaroidImageView = _polaroidImageView;
@synthesize polaroidContentImageView = _polaroidContentImageView;
@synthesize imagePickerPopover = _imagePickerPopover;


-(id)initWithInspectionPopup:(AGSPopup *)inspectionPopup andFeatureToInspectPopup:(AGSPopup *)toInspectPopup;
{
    self = [super initWithNibName:@"InspectionForm" bundle:nil];
    if (self) {
        self.inspectionEditingPopup = inspectionPopup;
        self.featureToInspectPopup = toInspectPopup;
    }
    
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.paperImageView.image = [UIImage imageNamed:@"inspection_form.png"];
    self.stampImageView.image = [UIImage imageNamed:@"Stamp_Outline.png"];
    
    //save original attributes in case they decide to cancel
    self.originalFeatureAttributes = [[self.inspectionEditingPopup.graphic allAttributes] mutableCopy];
    
    self.attributeUtility = [[AttributeUtility alloc] initWithPopup:self.inspectionEditingPopup];
    
    //create editable field infos array
    self.editableFieldInfos = [NSMutableArray arrayWithCapacity:self.inspectionEditingPopup.popupInfo.fieldInfos.count];
    for (AGSPopupFieldInfo *fi in self.inspectionEditingPopup.popupInfo.fieldInfos)
    {
        if (fi.editable) {
            [self.editableFieldInfos addObject:fi];
        }
    }
        
    //Prepopulate inspection form with values from the feature being inspected. This example assumes that attributes
    //with the same names are of the same type and just assigns those blindly to the inspection. For a real
    //app, a more defensive approach would be nice here
    NSArray *inspectionFieldNames = [[self.inspectionEditingPopup.graphic allAttributes] allKeys];
    NSArray *featureFieldNames = [[self.featureToInspectPopup.graphic allAttributes] allKeys];
    NSArray *offLimitsFieldNames = [NSArray arrayWithObjects:@"OBJECTID", @"GlobalID", nil];
    
    for (NSString *fieldName in featureFieldNames) {
        if ([inspectionFieldNames containsObject:fieldName] && ![offLimitsFieldNames containsObject:fieldName]) {
            id featureValue = [self.featureToInspectPopup.graphic attributeForKey:fieldName];
            [self.inspectionEditingPopup.graphic setAttribute:featureValue forKey:fieldName];
        }
    }
    
    //prepopulate date fields with current date. Dates won't be editable in this example
    for (AGSPopupFieldInfo *fi in self.inspectionEditingPopup.popupInfo.fieldInfos)
    {
        AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
        if ([self.attributeUtility isADateField:field]) {
            NSNumber *dateNum = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000.0];
            [self.inspectionEditingPopup.graphic setAttribute:dateNum forKey:fi.fieldName];
        }
    }
    
    
    //populate the label in top right of inspection form with first non-null string seen in attributes
    for (AGSPopupFieldInfo *fi in self.featureToInspectPopup.popupInfo.fieldInfos){
        AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
        if ([self.attributeUtility isAStringField:field]) {
            
            NSString *firstString = [self.featureToInspectPopup.graphic attributeForKey:fi.fieldName];
            
            //don't use if string is nil
            if (!firstString || ((NSNull *)firstString == [NSNull null]) ) {
                continue;
            }
            
            //if string is too long, cut off and ellipse
            if (([firstString length] > kMaxSizeString)) {
                firstString = [firstString substringToIndex:8];
                firstString = [firstString stringByAppendingString:@"..."];
            }
            
            self.leaseLabel.text = firstString;
            break;
        }
    }
    
    self.leaseLabel.textColor = [UIColor colorWithRed:212.0/255.0 green:0 blue:0 alpha:1.0];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.editableFieldInfos.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (InspectionFormTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"InspectionFormTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    InspectionFormTableViewCell *inspectionCell = (InspectionFormTableViewCell *)cell;
    
    int row = indexPath.row;
    
    AGSPopupFieldInfo *fi = [self.editableFieldInfos objectAtIndex:row];
    
    inspectionCell.fieldName.text = fi.label;

    AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    inspectionCell.fieldResult.text  = [self.attributeUtility attributeStringForField:field];
    
    //set tag on text field so we can get a handle on it later
    inspectionCell.fieldResult.tag = row + kCellOffsetTag;
    inspectionCell.fieldResult.delegate = self;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    //App only works in portrait. If app is destined for the app store, you might consider
    //making the app work in all orientations as suggested by Apple's iPad Human Interface Guidelines(HIG).
    return (interfaceOrientation == UIInterfaceOrientationPortrait  ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Button Interaction
-(IBAction)cancelInspection
{
    if([self.delegate respondsToSelector:@selector(inspectionFormDidCancel:)])
    {
        [self.delegate inspectionFormDidCancel:self];
    }
}

-(IBAction)finishInspection
{
    if (self.attachedImage) {
        AGSAttachmentManager *am = [self.attributeUtility.featureLayer attachmentManagerForFeature:self.inspectionEditingPopup.graphic];
        [am addAttachmentAsJpgWithImage:self.attachedImage name:@"Polaroid Image"];
    }
    
    if([self.delegate respondsToSelector:@selector(inspectionFormDidFinishWithNewInspection:)])
    {
        [self.delegate inspectionFormDidFinishWithNewInspection:self.inspectionEditingPopup];
    }
}

-(IBAction)takePicture
{
    BOOL bIsCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (bIsCameraAvailable)
    {
        //we have a camera, so let the user pick between that and the saved photo roll
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                 delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Choose Existing Photo", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        actionSheet.delegate = self;
        [actionSheet showFromRect:self.takePictureButton.frame inView:self.view animated:YES];
    }
    else {
        [self showImagePickerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
    }  	
}

#pragma mark -
#pragma mark DomainPickerDelegate
-(void)domainPickerDidFinish:(DomainPickerViewController *)dpvc
{
    if (self.attributeUtility.featureLayer){
		if ([dpvc.fieldInfo.fieldName isEqualToString:self.attributeUtility.featureLayer.typeIdField]){
			if (![dpvc.value isEqual:[self.inspectionEditingPopup.graphic attributeForKey:dpvc.fieldInfo.fieldName]]){
                
				// change values based on new template chosen
				AGSFeatureLayer *fl = self.attributeUtility.featureLayer;
				AGSFeatureTemplate *t = dpvc.templateChosen;
				AGSGraphic *p = t.prototype;
				AGSGraphic *g = self.inspectionEditingPopup.graphic;
				for (NSString *fieldName in [[p allAttributes] allKeys]){
					[g setAttribute:[p attributeForKey:fieldName] forKey:fieldName];
				}
				// Update popupUtility.featureType
				for (AGSFeatureType *type in fl.types){
					if ([type.templates containsObject:t]){
						self.attributeUtility.featureType = type;
					}
				}
			}
		}
	}
    
    [self.inspectionEditingPopup.graphic setAttribute:dpvc.value forKey:dpvc.fieldInfo.fieldName];
    [self.tableView reloadData];
    
    [self.domainPickerVC.view removeFromSuperview];
    self.domainPickerVC = nil;
    
    [self.tableView reloadData];
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
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    int tag = textField.tag - kCellOffsetTag;
    
    AGSPopupFieldInfo *fi = [self.editableFieldInfos objectAtIndex:tag];
    AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    if ([self.attributeUtility isAStringField:field]) {
        return YES;
    }
    else if([self.attributeUtility isANumberField:field])
    {
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        return YES;
    }
    //don't want *anything* to happen with a date field
    else if([self.attributeUtility isADateField:field])
    {
        return NO;
    }
    
    //TODO: Assume we need a domain picker now.  Range domains aren't yet supported.
    
    //Need to show domain picker for field
    self.domainPickerVC = [[DomainPickerViewController alloc] initWithFieldInfo:fi andAttributeUtility:self.attributeUtility];
    self.domainPickerVC.value = [self.inspectionEditingPopup.graphic attributeForKey:fi.fieldName];
    self.domainPickerVC.delegate = self;
    
    [self.view.superview addSubview:self.domainPickerVC.view];
    
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self textFieldDidEndEditing:textField];
    return YES;
}

/*-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    int tag = textField.tag = kCellOffsetTag;
    
    //Need to do something with tag here to make sure we show the right type to collect
}  */

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    int tag = textField.tag - kCellOffsetTag;
    
    //get fieldInfo for tag
    AGSPopupFieldInfo * fi = [self.editableFieldInfos objectAtIndex:tag];
    
    AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    //if we directly edited the text field, we either have a number or a string
    if ([self.attributeUtility isAStringField:field]) {
        NSString *text = (textField.text && textField.text.length > 0) ? textField.text : @"";
        
        [self.inspectionEditingPopup.graphic setAttribute:text forKey:fi.fieldName];
    }
    else if([self.attributeUtility isANumberField:field])
    {
        id numValue = [self getValueFromTextField:textField forFeatureType:field.type];
        
        [self.inspectionEditingPopup.graphic setAttribute:numValue forKey:fi.fieldName];
    }
    
    [textField resignFirstResponder];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Image Picker and Related Methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image == nil) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //kill popover
    [self.imagePickerPopover dismissPopoverAnimated:YES];
    self.imagePickerPopover = nil;
    
    //finally show image
    [self showPolaroidOfImage:image];
}

-(UIImageView *)paperClipImageView
{
    if(_paperClipImageView == nil)
    {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paperclip_piece1.png"]];
        iv.frame = CGRectMake(34, 777, 87, 147);
        self.paperClipImageView = iv;
    }
    
    return _paperClipImageView;
}

-(UIImageView *)polaroidImageView
{
    if (_polaroidImageView == nil) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rotated_polaroid.png"]];
        iv.frame = CGRectMake(50, 480, 386, 420);
        self.polaroidImageView = iv;
    }
    
    return _polaroidImageView;
}

-(UIImageView *)polaroidContentImageView
{
    if (_polaroidContentImageView == nil) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(81, 505, 325, 320)];
        self.polaroidContentImageView = iv;
    }
    
    return _polaroidContentImageView;
}

-(void)showPolaroidOfImage:(UIImage *)image
{
    //already showing
    if (_showingPolaroid)
        return;
    
    //add polaroid
    [self.view addSubview:self.polaroidImageView];
    
    //add polaroid content
    self.polaroidContentImageView.alpha = 0.0;  //set to zero so we can animate content
    self.polaroidContentImageView.image = image;
    self.polaroidContentImageView.transform = CGAffineTransformMakeRotation(kPolaroidRotationAngle);
    [self.view addSubview:self.polaroidContentImageView];
    
    //add paperclip to hold down
    [self.view addSubview:self.paperClipImageView];
    
    //hide camera button
    self.takePictureButton.hidden = YES;
    
    _showingPolaroid = YES;
    
    //Animate polaroid by setting alpha from 0.0 to 1.0
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:kPolaroidDevelopmentTime];
    
    self.polaroidContentImageView.alpha = 1.0;
    
    [UIView commitAnimations];
    
    //retain our image for attaching to feature later
    self.attachedImage = image;
}

-(void)showImagePickerWithType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.allowsEditing = YES;
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    imagePicker.delegate = self;
    
    self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
    self.imagePickerPopover.delegate = self;
    [self.imagePickerPopover presentPopoverFromRect:self.takePictureButton.frame 
                                             inView:self.view 
                           permittedArrowDirections:UIPopoverArrowDirectionAny 
                                           animated:YES];
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePickerPopover = nil;
}

#pragma mark -
#pragma mark Internal
-(id)getValueFromTextField:(UITextField *)textField forFeatureType:(AGSFieldType)fieldType
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

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];

    self.paperImageView = nil;
    self.tableView = nil;
    self.takePictureButton = nil;
    self.stampImageView = nil;
    self.leaseLabel = nil;
    
    self.paperClipImageView = nil;
    self.polaroidImageView = nil;
    self.polaroidContentImageView = nil;
    
    self.domainPickerVC = nil;
}




@end
