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

#import "FeatureDetailsViewController.h"
#import "FeatureTypeViewController.h"
#import "ImageViewController.h"
#import "MoviePlayerViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>

#import "CodedValueUtility.h"
#import "OnlineOfflineFeatureLayer.h"

@interface FeatureDetailsViewController ()

-(void)doneSucceeded;
-(void)doneFailed;        

@end

@implementation FeatureDetailsViewController
@synthesize feature = _feature;
@synthesize featureGeometry = _featureGeometry;
@synthesize featureLayer = _featureLayer;
@synthesize attachments = _attachments;
@synthesize date = _date;
@synthesize dateFormat = _dateFormat;
@synthesize timeFormat = _timeFormat;
@synthesize attachmentInfos = _attachmentInfos;
@synthesize operations = _operations;
@synthesize retrieveAttachmentOp = _retrieveAttachmentOp;

#pragma mark - helper methods

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)filepathIsJPG:(NSString*)filepath{
	return [[[filepath pathExtension]lowercaseString] isEqualToString:@"jpg"];
}

-(BOOL)filepathIsMOV:(NSString*)filepath{
	return [[[filepath pathExtension]lowercaseString] isEqualToString:@"mov"];
}

-(NSString*)saveDataToTempFile:(NSData*)data mediaType:(NSString*)mediaType{
	NSString *ext = nil;
	if ([mediaType isEqualToString:(NSString*)kUTTypeImage]){
		ext = @"jpg";
	}
	else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
		ext = @"mov";
	}
	
	NSString *filename = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate], ext]];
	[data writeToFile:filename atomically:NO];
	return filename;
}

-(NSString*)saveImageToTempFile:(UIImage*)image{
	NSData *imageData = UIImageJPEGRepresentation(image, .35);
	return [self saveDataToTempFile:imageData mediaType:(NSString*)kUTTypeImage];
}

- (UIImage *)thumbnailForImageWithPath:(NSString*)fullPathToMainImage size:(float)size {
	
	NSString *subdir = [fullPathToMainImage stringByDeletingLastPathComponent];
	NSString *filename = [fullPathToMainImage lastPathComponent];
	NSString *extension = [fullPathToMainImage pathExtension];
	NSString *fullPathToThumbImage = [subdir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%dx%d.%@",filename, (int)size, (int)size, extension]];
	
	UIImage *thumbnail;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:fullPathToThumbImage] == YES) {
		thumbnail = [UIImage imageWithContentsOfFile:fullPathToThumbImage];
	}
	else {
		UIImage *mainImage = [UIImage imageWithContentsOfFile:fullPathToMainImage];
		UIImageView *mainImageView = [[[UIImageView alloc] initWithImage:mainImage]autorelease];
		BOOL widthGreaterThanHeight = (mainImage.size.width > mainImage.size.height);
		float sideFull = (widthGreaterThanHeight) ? mainImage.size.height : mainImage.size.width;
		CGRect clippedRect = CGRectMake(0, 0, sideFull, sideFull);
		// creating a square context the size of the final image which we will then
		// manipulate and transform before drawing in the original image
		UIGraphicsBeginImageContext(CGSizeMake(size, size));
		CGContextRef currentContext = UIGraphicsGetCurrentContext();
		CGContextClipToRect( currentContext, clippedRect);
		CGFloat scaleFactor = size/sideFull;
		if (widthGreaterThanHeight) {
			// a landscape image – make context shift the original image to the left when drawn into the context
			CGContextTranslateCTM(currentContext, -((mainImage.size.width - sideFull) / 2) * scaleFactor, 0);
		}
		else {
			// a portrait image – make context shift the original image upwards when drawn into the context
			CGContextTranslateCTM(currentContext, 0, -((mainImage.size.height - sideFull) / 2) * scaleFactor);
		}
		// this will automatically scale any CGImage down/up to the required thumbnail side (size)
		// when the CGImage gets drawn into the context on the next line of code
		CGContextScaleCTM(currentContext, scaleFactor, scaleFactor);
		[mainImageView.layer renderInContext:currentContext];
		thumbnail = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		NSData *imageData = UIImagePNGRepresentation(thumbnail);
		[imageData writeToFile:fullPathToThumbImage atomically:YES];
		thumbnail = [UIImage imageWithContentsOfFile:fullPathToThumbImage];
	}
	return thumbnail;
}

-(NSURL*)urlFromFilePath:(NSString*)filepath{
	return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",filepath]];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// we have a cancel and commit button for new features
	if (_newFeature){
		UIBarButtonItem *cancel = [[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)]autorelease];
		self.navigationItem.leftBarButtonItem = cancel;
		
		UIBarButtonItem *commit = [[[UIBarButtonItem alloc]initWithTitle:@"Commit" style:UIBarButtonItemStylePlain target:self action:@selector(commit)]autorelease];
		self.navigationItem.rightBarButtonItem = commit;
		
		self.navigationItem.title = @"New Trail";
	}
	else {
		self.navigationItem.title = @"Trail Details";
	}
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	NSDictionary* attributes = [self.feature allAttributes];
	self.navigationItem.rightBarButtonItem.enabled = (attributes!=nil && [attributes count]>0) ;
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark init method

-(id)initWithFeatureLayer:(OnlineOfflineFeatureLayer*)featureLayer feature:(AGSGraphic *)feature featureGeometry:(AGSGeometry*)featureGeometry{
	
	if (self = [super initWithStyle:UITableViewStylePlain]){
		self.featureLayer = featureLayer;
		self.featureLayer.editingDelegate = self;
		self.featureGeometry = featureGeometry;
        self.feature = feature;
		self.operations = [NSMutableArray array];
		
		// if the attributes are nil, it is a new feature, set flat
		if (!feature){
			_newFeature = YES;
			self.attachments = [NSMutableArray array];
		}
		
		// otherwise it is an existing feature, so we cache the objectId,
		// set the newFeature flag, and kick off an operation to get 
		// the attachments
		else {
			_objectId = [self.featureLayer objectIdForFeature:self.feature];
			_newFeature = NO;
            NSOperation* op = [self.featureLayer queryAttachmentInfosForObjectId:_objectId];
            if(op)
                [self.operations addObject:op];
		}

		// set initial date
		self.date = [NSDate dateWithTimeIntervalSinceNow:0];
		
		// set up the formatters
		self.dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[self.dateFormat setDateFormat:@"MMMM dd, yyyy"];
		
        //we're currently not using time
		self.timeFormat = [[[NSDateFormatter alloc] init] autorelease];
		[self.timeFormat setDateFormat:@"HH:mm:ss"];
	}
	
	return self;
}

#pragma mark helper methods

-(void)cancel{
	// when the cancel button is pressed
	
	// this will eventually dealloc this VC and the operations that haven't completed yet
	// will be cancelled
	[self.navigationController popViewControllerAnimated:YES];
}

-(void)commit{
	// when the commit button is pressed
	
	// disable the commit button
	self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.featureLayer.bOnline)
    {
        // kick off the add feature operation
        [self.operations addObject:[self.featureLayer addFeatures:[NSArray arrayWithObject:self.feature]]];	
    }
    else {
        //add features offline
        [self.featureLayer addOfflineFeature:self.feature withAttachments:self.attachments];
        _objectId = -1; //set up dummy id
		[self doneSucceeded];
    }
}

-(void)doneSucceeded{
	// called when we are done and the feature was added successfully
	
	// pop the view controller
	[self.navigationController popViewControllerAnimated:YES];
	
    NSString *messageString = @"You have successfully added a trail.";
    if (self.featureLayer.bOnline)
    {
        messageString = [messageString stringByAppendingString:[NSString stringWithFormat:@" Confirmation number: %i", _objectId]];
    }

	// show an alert
	UIAlertView *alertView = [[[UIAlertView alloc]initWithTitle:@"Trail Added"
														message:messageString
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil]autorelease];
	[alertView show];
}

-(void)doneFailed{
	// called when we are done and the feature was not successfully added
	
	// pop the view controller
	[self.navigationController popViewControllerAnimated:YES];
	
	// show an alert
	UIAlertView *alertView = [[[UIAlertView alloc]initWithTitle:@"Error"
														message:@"There was an error adding the trail. Please try again."
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil]autorelease];
	[alertView show];
}

-(void)didSelectFeatureType:(FeatureTypeViewController *)ftvc
{
    //get feature from FeatureTypeViewController
    self.feature = ftvc.feature;
    
    //set geometry
    self.feature.geometry = self.featureGeometry;
    
    // set the recordedon value; the other default values will come from the template
    NSTimeInterval timeInterval = [self.date timeIntervalSince1970];
    [self.feature setAttributeWithDouble:(timeInterval * 1000) forKey:@"recordedon" ];
    
    
    //redraw the tableView
    [self.tableView reloadData];
}

#pragma mark featureLayerEditingDelegate methods

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didQueryAttachmentInfosWithResults:(NSArray *)attachmentInfos{
	
	// called by the feature layer when the queryAttachmentInfos is completed
	
	NSLog(@"got attachment infos...");
	
	// remove the operation from the array
	[self.operations removeObject:op];
	
	// set the attachmentInfos
	self.attachmentInfos = attachmentInfos;
	
	// initialize all the attachments to NSNull
	self.attachments = [NSMutableArray arrayWithCapacity:attachmentInfos.count];
	for (int i=0; i<self.attachmentInfos.count; i++){
		[self.attachments addObject:[NSNull null]];
	}
	
	// reload the table
	[self.tableView reloadData];
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailQueryAttachmentInfosWithError:(NSError *)error{
	// called when the featurelayer fails to query for attachments
	
	// set the attachmentInfos
	self.attachmentInfos = [NSMutableArray array];
	
	// remove the operation from the array
	[self.operations removeObject:op];
	
	// reload the table
	[self.tableView reloadData];
	
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults{
	// called when feature layer is done with feature edits (in this case, done adding the feature)
	
	// remove operation
	[self.operations removeObject:op];
	
	// if can't add feature, call doneFailed
	AGSEditResult *addResult = [editResults.addResults objectAtIndex:0];
	if (!addResult.success){
		NSLog(@"failed to add feature");
		[self doneFailed];
		return;
	}
	
	// if added feature, set the objectId
	NSLog(@"added feature: %d",addResult.objectId);
	_objectId = addResult.objectId;
	
	if (self.attachments.count > 0){
		// add the attachments
		for (int i=0; i<self.attachments.count; i++){
			id file = [self.attachments objectAtIndex:i];
			if ([file isKindOfClass:[NSURL class]]){
				NSData *data = [NSData dataWithContentsOfURL:file];
				[self.operations addObject:[self.featureLayer addAttachment:addResult.objectId data:data filename:[[file absoluteString]lastPathComponent] ]];
			}
			else if ([file isKindOfClass:[NSString class]]){
				[self.operations addObject:[self.featureLayer addAttachment:addResult.objectId filepath:[self.attachments objectAtIndex:i]]];
			}
		 }
	}
	else {
		// if no attachments, done
		[self doneSucceeded];
	}

}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailFeatureEditsWithError:(NSError *)error{
	// called when the feature layer fails to perform the feature edits (in the case fails to add the feature)
	
	NSLog(@"error adding feature: %@", error.description);
	
	// remove the operation, call doneFailed
	[self.operations removeObject:op];
	[self doneFailed];
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didAttachmentEditsWithResults:(AGSFeatureLayerAttachmentResults *)attachmentResults{
	// called when the feature layer adds the attachment
	
	// remove the operation
	[self.operations removeObject:op];
	
	if (!attachmentResults.addResult.success){
		NSLog(@"failed to add attachment.");
	}
	else {
		NSLog(@"added attachment: %d",attachmentResults.addResult.objectId);
	}

	// as we add attachments, we are removing them from the array, so that we know when we are done adding all the attachments
	if (self.operations.count == 0){
		// if we get to 0, we are done
		[self doneSucceeded];
	}
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailAttachmentEditsWithError:(NSError *)error{
	// called when the feature layer fails to add the attachment
	
	NSLog(@"error adding attachment");
	
	// remove the operation
	[self.operations removeObject:op];
	
	// as we add attachments, we are removing them from the array, so that we know when we are done adding all the attachments
	if (self.operations.count == 0){
		// if we get to 0, we are done
		[self doneSucceeded];
	}	
	
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didRetrieveAttachmentWithData:(NSData *)attachmentData{
	// called when we get back the attachment data
	
	NSLog(@"got attachment data");
	
	// remove the operation
	[self.operations removeObject:op];
	
	// set cached variable to nil, so we know we aren't performing a "retrieve attachment"
	self.retrieveAttachmentOp = nil;
	
	// save image to temp file
	// add the filename to the attachments array, so we don't have to get it next time
	if (attachmentData != nil){
		AGSAttachmentInfo *ai = [self.attachmentInfos objectAtIndex:self.tableView.tag];
		if ([ai.contentType isEqualToString:@"image/jpeg"]){
			NSString *filepath = [self saveDataToTempFile:attachmentData mediaType:(NSString*)kUTTypeImage];
			[self.attachments replaceObjectAtIndex:self.tableView.tag withObject:filepath];
			
			// create an image
			UIImage *image = [UIImage imageWithData:attachmentData];
			// show the image
			ImageViewController *vc = [[[ImageViewController alloc]initWithImage:image]autorelease];
			[self.navigationController pushViewController:vc animated:YES];
		}
		else if ([ai.contentType isEqualToString:@"video/quicktime"]){
			NSString *filepath = [self saveDataToTempFile:attachmentData mediaType:(NSString*)kUTTypeMovie];
			[self.attachments replaceObjectAtIndex:self.tableView.tag withObject:filepath];
			MoviePlayerViewController *vc = [[[MoviePlayerViewController alloc]initWithURL:[self urlFromFilePath:filepath]]autorelease];
			[self.navigationController pushViewController:vc animated:YES];
		}
	}
	
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailRetrieveAttachmentWithError:(NSError *)error{
	// called when the feature layer fails to retrieve the attachment data
	NSLog(@"failed to retrieve attachment");
	
	// remove the operation
	[self.operations removeObject:op];
	
	// set the cached variable to nil, so we know we aren't performing a "retrieve attachment"
	self.retrieveAttachmentOp = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	
	// feature type
	if (section == 0){
		return 1;
	}
	
	// attachments
	else if (section == 1){
		if (_newFeature){
			return self.attachments.count + 1;
		}
		else {
			if (self.attachmentInfos){
				if (self.attachmentInfos.count == 0){
					return 1;
				}
				else {
					return self.attachmentInfos.count;
				}
			}
			else {
				return 1;
			}
		}

	}
	
	// details
	else if (section == 2){
		return 4;
	}
	
	return 0;
}


-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	// feature type
	if (section == 0){
		return @"Trail";
	}
	
	// attachments
	else if (section == 1){
		return @"Media Attachments";
	}
	
	// details
	else if (section == 2){
		return @"Details";
	}
	return nil;
}

-(AGSField*)findStatusField{
	// helper method to find the status field
	for (int i=0; i<self.featureLayer.fields.count; i++){
		AGSField *field = [self.featureLayer.fields objectAtIndex:i];
		if ([field.name isEqualToString: @"status"]){
			return field;
		}
	}
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	
	// section 0 is the feature type
	if (indexPath.section == 0){
		
		static NSString *typeCellIdentifier = @"typeCell";
		
		cell = [tableView dequeueReusableCellWithIdentifier:typeCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:typeCellIdentifier] autorelease];
		}
		
		cell.imageView.image = nil;
		cell.textLabel.text = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
        if (!self.feature){
            //no feature until we select a feature type
			cell.textLabel.text = @"Choose Trail Type";
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		else {
			cell.textLabel.text = [CodedValueUtility getCodedValueFromFeature:self.feature forField:@"trailtype" inFeatureLayer:self.featureLayer];
			if (_newFeature) cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			if (_newFeature) cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.imageView.image = [self.featureLayer.renderer swatchForFeature:self.feature size:CGSizeMake(20, 20)];
		}

	}
	
	// section 1 is the attachments
	else if (indexPath.section == 1){
		
		static NSString *attachmentsCellIdentifier = @"attachmentsCell";
		
		cell = [tableView dequeueReusableCellWithIdentifier:attachmentsCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:attachmentsCellIdentifier] autorelease];
		}
		
		cell.imageView.image = nil;
		cell.textLabel.text = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		// for creating a new feature, we allow them to add a picture
		// and view or remove pictures
		if (_newFeature){
			if (indexPath.row == self.attachments.count){
				cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
				cell.textLabel.text = @"Add Photo/Video";
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			else {
				NSString *filepath = [self.attachments objectAtIndex:indexPath.row];
				if ([self filepathIsJPG:filepath]){
					cell.textLabel.text = [NSString stringWithFormat:@"%@ %d",@"Picture",indexPath.row + 1];
					cell.imageView.image = [self thumbnailForImageWithPath:[self.attachments objectAtIndex:indexPath.row] size:36];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
				else {
					cell.textLabel.text = [NSString stringWithFormat:@"%@ %d",@"Video",indexPath.row + 1];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}

			}
		}
		
		// for viewing attributes of an existing feature, we need to show them either
		// a "loading" message, "none" message, or list of media attachments
		else {
			if (self.attachmentInfos == nil){
				cell.textLabel.text = @"Loading...";
			}
			else if (self.attachmentInfos.count == 0){
				cell.textLabel.text = @"None";
			}
			else {
				AGSAttachmentInfo *ai = [self.attachmentInfos objectAtIndex:indexPath.row];
				cell.textLabel.text = ai.name;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
				// if we've already retrieved the photo, show a thumbnail
				if ([ai.contentType isEqualToString:@"image/jpeg"] && [self.attachments objectAtIndex:indexPath.row] != [NSNull null]){
					cell.imageView.image = [self thumbnailForImageWithPath:[self.attachments objectAtIndex:indexPath.row] size:36];
				}
			}
		}
	}
	
	// section 2 is the feature details
	if (indexPath.section == 2){
		static NSString *detailsCellIdentifier = @"detailsCell";
		
		cell = [tableView dequeueReusableCellWithIdentifier:detailsCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:detailsCellIdentifier] autorelease];
		}
		
		cell.imageView.image = nil;
		cell.textLabel.text = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
        AGSField *field = nil;
		if (indexPath.row == 0){
			cell.detailTextLabel.text = [CodedValueUtility getCodedValueFromFeature:self.feature forField:@"condition" inFeatureLayer:self.featureLayer];
            field = [CodedValueUtility findField:@"condition" inFeatureLayer:self.featureLayer];
			cell.textLabel.text = field.alias;
		}
		else if (indexPath.row == 1){
            BOOL exists;
            NSNumber *recorededOn =
            [NSNumber numberWithDouble:[self.feature attributeAsDoubleForKey:@"recordedon" exists:&exists]];
            NSString *detailString = @"";
            if (recorededOn && (recorededOn != (id)[NSNull null]))
            {
                //attribute dates/times are in milliseconds; NSDate dates are in seconds
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:([recorededOn doubleValue] / 1000.0)];
                detailString = [self.dateFormat stringFromDate:date];
            }
			cell.detailTextLabel.text = detailString;
            
            field = [CodedValueUtility findField:@"recordedon" inFeatureLayer:self.featureLayer];
			cell.textLabel.text = field.alias;
		}
		else if (indexPath.row == 2){
			cell.detailTextLabel.text = [CodedValueUtility getCodedValueFromFeature:self.feature forField:@"difficulty" inFeatureLayer:self.featureLayer];
            field = [CodedValueUtility findField:@"difficulty" inFeatureLayer:self.featureLayer];
			cell.textLabel.text = field.alias;
		}
		else if (indexPath.row == 3){
            NSString *value = [self.feature attributeAsStringForKey:@"notes"];
			cell.detailTextLabel.text = (value == (id)[NSNull null] ? @"" : value);
            field = [CodedValueUtility findField:@"notes" inFeatureLayer:self.featureLayer];
			cell.textLabel.text = field.alias;
		}
        
//        UITableViewCellAccessoryType accType = UITableViewCellAccessoryNone;
//        if (field && field.editable)
//        {
//            accType = UITableViewCellAccessoryDisclosureIndicator;
//        }
//        
//        //set the accessory type based on whether the field is editable or not.
//        //note:  currently we don't do any editing of attributes...
//        cell.accessoryType = accType;
    }
	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
#pragma mark Table view delegate

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// don't allow selection if it is a new feature and we are in the process of committing
	if (_newFeature && self.operations.count > 0){
		return;
	}
	
	if (_newFeature && indexPath.section == 0){
		// if creating a new feature and they clicked on the feature type, then let them choose a
		// feature template
		FeatureTypeViewController *ftvc = [[[FeatureTypeViewController alloc]init]autorelease];
		ftvc.featureLayer = self.featureLayer;
		ftvc.feature = self.feature;
        ftvc.completedDelegate = self;
		
		[self.navigationController pushViewController:ftvc animated:YES];
	}
	
	else if (indexPath.section == 1){
		
		if (_newFeature){ 
			// if creating a new feature and they click on an attachment
			
			if (indexPath.row == self.attachments.count){
				// if they click on "Add"
				UIImagePickerController *imgPicker = [[[UIImagePickerController alloc] init]autorelease];
				imgPicker.delegate = self;
				if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
					imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
					imgPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imgPicker.sourceType];
					imgPicker.allowsEditing = NO;
					imgPicker.videoQuality = UIImagePickerControllerQualityTypeLow;
					imgPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imgPicker.sourceType];
				}
				else {
					imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				}
                [self presentViewController:imgPicker animated:YES completion:nil];
			}
			else {
				// if they click on an existing media attachment
				UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:@"What would you like to do?"
																			delegate:self
															   cancelButtonTitle:@"Cancel"
														  destructiveButtonTitle:@"Remove"
																otherButtonTitles:@"View",nil]autorelease];
				actionSheet.tag = indexPath.row;
				[actionSheet showInView:self.view];
			}
		}
		else {
			// if they are viewing an existing feature
			
			if (self.attachmentInfos.count > 0){
				
				// first cancel any retrieve operation already going on
				if (self.retrieveAttachmentOp != nil){
					[self.retrieveAttachmentOp cancel];
					[self.operations removeObject:self.retrieveAttachmentOp];
					self.retrieveAttachmentOp = nil;
				}
				
				if ([self.attachments objectAtIndex:indexPath.row] == [NSNull null]){
					
					// if they click on a photo/video that we don't have, retrieve it
					
					// set tag to be used later
					self.tableView.tag = indexPath.row;
					
					// kick off operation
					AGSAttachmentInfo *ai = [self.attachmentInfos objectAtIndex:indexPath.row];
					if ([ai.contentType isEqualToString:@"image/jpeg"]){
						self.retrieveAttachmentOp = [self.featureLayer retrieveAttachmentForObjectId:_objectId attachmentId:ai.attachmentId];
						[self.operations addObject:self.retrieveAttachmentOp];
					}
					else if([ai.contentType isEqualToString:@"video/quicktime"]){
						self.retrieveAttachmentOp = [self.featureLayer retrieveAttachmentForObjectId:_objectId attachmentId:ai.attachmentId];
						[self.operations addObject:self.retrieveAttachmentOp];
					}
				}
				else {
					AGSAttachmentInfo *ai = [self.attachmentInfos objectAtIndex:indexPath.row];
					if ([ai.contentType isEqualToString:@"image/jpeg"]){
						// if we already have the image, show it
						UIImage *image = [UIImage imageWithContentsOfFile:[self.attachments objectAtIndex:indexPath.row]];
						ImageViewController *vc = [[[ImageViewController alloc]initWithImage:image]autorelease];
						[self.navigationController pushViewController:vc animated:YES];
					}
					else if ([ai.contentType isEqualToString:@"video/quicktime"]){
						// if we already have the video, show it
						NSString *filepath = [self.attachments objectAtIndex:indexPath.row];
						MoviePlayerViewController *vc = [[[MoviePlayerViewController alloc]initWithURL:[self urlFromFilePath:filepath]]autorelease];
						[self.navigationController pushViewController:vc animated:YES];
					}
				}

			}
		}
	}	
}

#pragma mark Action sheet delegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == actionSheet.cancelButtonIndex){
		// cancel
	}
	else if (buttonIndex == actionSheet.destructiveButtonIndex){
		// remove media attachment
		[self.attachments removeObjectAtIndex:actionSheet.tag];
		[self.tableView reloadData];
	}
	else{
		// view media attachment
		// For existing features, if it is a picture, it will be a string
		// if it is a quicktime video, it will be a URL
		id filepath = [self.attachments objectAtIndex:actionSheet.tag];
		if ([filepath isKindOfClass:[NSString class]]){
			UIImage *image = [UIImage imageWithContentsOfFile:[self.attachments objectAtIndex:actionSheet.tag]];
			ImageViewController *vc = [[[ImageViewController alloc]initWithImage:image]autorelease];
			[self.navigationController pushViewController:vc animated:YES];
		}
		else if ([filepath isKindOfClass:[NSURL class]]){
			MoviePlayerViewController *vc = [[[MoviePlayerViewController alloc]initWithURL:filepath]autorelease];
			[self.navigationController pushViewController:vc animated:YES];
		}
	}
}

#pragma mark Image Picker delegate methods
									  
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{

	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	
	NSLog(@"%@",[info objectForKey:UIImagePickerControllerMediaType]);
	NSLog(@"%@",info);
	
	if ([mediaType isEqualToString:(NSString*)kUTTypeImage]){
		// once they take/choose a picture, add it to the attachments collection and reload the table data
		UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
		
		// save image to tmp folder
		NSString *filename = [self saveImageToTempFile:image];
		
		// add filename to attachments
		[self.attachments addObject:filename];
	}
	else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
		// save image to tmp folder
		NSURL *fileurl = [info objectForKey:UIImagePickerControllerMediaURL];
		// add filename to attachments
		[self.attachments addObject:fileurl];
	}
	
	[self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc {
	
	// cancel any ongoing operations
	for (NSOperation *op in self.operations){
		[op cancel];
	}
	
	self.retrieveAttachmentOp = nil;
	
	// set delegate to nil so that the feature layer doesn't try to access
	// a dealloc'd object
	self.featureLayer.editingDelegate = nil;
	
	self.feature = nil;
	self.featureGeometry = nil;
	self.featureLayer = nil;
	self.attachments = nil;
	self.date = nil;
	self.dateFormat = nil;
	self.timeFormat = nil;
	self.attachmentInfos = nil;
	self.operations = nil;
    [super dealloc];
}


@end

