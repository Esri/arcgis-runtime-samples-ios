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

#import "NotesViewController.h"
#import "LoadingView.h"

//url for the related records of the incident later. One incident can have multiple related records. 
//They are related by the objectid of the incidents. 
#define kIncidentNotesLayerURL @"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/1"


#define ROW_HEIGHT 60


@interface NotesViewController() 

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) AGSFeatureLayer *incidentLayer;
@property (nonatomic, strong) AGSFeatureLayer *incidentNotesLayer;
@property (nonatomic, strong) NSNumber *incidentOID;
@property (nonatomic, strong) NSMutableArray *relatedFeaturesResultsArray;
@property (nonatomic, strong) AGSPopupsContainerViewController* notesPopupVC;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSIndexPath *indexPathForDeleteOperation;


- (IBAction)addNewNote;
- (IBAction)done;

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;
- (void)warnUserOfErrorWithMessage:(NSString*)message;
- (void)queryRelatedRecords;

@end


@implementation NotesViewController

//cutom init method
- (id)initWithIncidentOID:(NSNumber*)incidentOID incidentLayer:(AGSFeatureLayer *)layer
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    self = [storyboard instantiateViewControllerWithIdentifier:@"NotesViewController"];
    if (self) {
        //store the incident Object ID locally
        self.incidentOID = incidentOID;       
        
        //Assign the incident layer. This is required for performing the query. 
        self.incidentLayer = layer;      
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //assigning the query delegate of the incident layer
    self.incidentLayer.queryDelegate = self;
    
    //set up the incident notes layer as a feature layer. we dont have to add this to the base map as this is a related record table. 
    self.incidentNotesLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:kIncidentNotesLayerURL] mode:AGSFeatureLayerModeSnapshot];
    
    //we're filtering the outfields because we only want to display these two fields to the end user.
    [self.incidentNotesLayer setOutFields:[NSArray arrayWithObjects:@"agree_with_incident", @"notes", nil]]; 
    self.incidentNotesLayer.editingDelegate = self;
    
    //query the incidents layer for the related notes. 
    [self queryRelatedRecords];
    
    //setting the custom row height to accomodate the image and the text properly
    self.tableView.rowHeight = ROW_HEIGHT;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    self.delegate = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Return the number of rows in the section. This corresponds to the count of the array of related features. 
    if([self.relatedFeaturesResultsArray count] > 0)
        return [self.relatedFeaturesResultsArray count];
    
    //Or return 1 if no record exists. 
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Two types of cells - Normal one for showing the related records and other for the empty cell
    static NSString *RecordsIdentifier = @"RecordCell";
    static NSString *NoRecordsIdentifier = @"NoRecordCell";
    
    UITableViewCell *cell;
    
    if([self.relatedFeaturesResultsArray count] > 0)
    {     
        cell = [tableView dequeueReusableCellWithIdentifier:RecordsIdentifier];

        if (cell == nil) {
            cell = [self tableViewCellWithReuseIdentifier:RecordsIdentifier];
        }
        // configureCell:cell forIndexPath: sets the text and image for the cell
        [self configureCell:cell forIndexPath:indexPath];  

    }                      
    
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:NoRecordsIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoRecordsIdentifier];
        }        
        cell.textLabel.text = @"No records found";
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.relatedFeaturesResultsArray count] > 0)
        //users can delete a related record by swiping on the table cell. 
        return UITableViewCellEditingStyleDelete;
    return UITableViewCellEditingStyleNone;    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    //Once the user initiates the deletion, the record is deleted from both the incidentnotes layer and the local array of features. 
    long oid = [self.incidentNotesLayer objectIdForFeature:[self.relatedFeaturesResultsArray objectAtIndex:indexPath.row]];
		
    if(oid > 0)
    {
        self.loadingView = [LoadingView loadingViewInView:self.notesPopupVC.view withText:@"Deleting record..."]; 
        //feature has a valid objectid, this means it exists on the server
        //and we simply update the exisiting feature
        [self.incidentNotesLayer deleteFeaturesWithObjectIds:[NSArray arrayWithObjects:[NSNumber numberWithLong:oid], nil]];
        
        //store the indexpath for updating the table view later. 
        self.indexPathForDeleteOperation = indexPath;
    }   
}

#pragma mark -
#pragma mark Configuring table view cells

#define IMAGE_TAG 1
#define NOTES_TAG 2

#define LEFT_COLUMN_OFFSET 10.0
#define IMAGE_SIDE 30.0
#define LEFT_COLUMN_WIDTH 30.0

#define RIGHT_COLUMN_OFFSET 50.0
#define RIGHT_COLUMN_WIDTH 230.0

#define MAIN_FONT_SIZE 18.0
#define LABEL_HEIGHT 26.0



- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier {
		
    //Create an instance of UITableViewCell and add tagged subviews for the image and notes.    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];    
	
    //Create label an image for the cell  
	UILabel *label;
	CGRect rect;
    
    // Create an image view for the quarter image.
	rect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
    
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
	imageView.tag = IMAGE_TAG;
	[cell.contentView addSubview:imageView];
	
	// Create a label for the time zone name.
	rect = CGRectMake(RIGHT_COLUMN_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, RIGHT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NOTES_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = NO;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
	return cell;
}


//this method fills the appropriate info in the cells according to the fields. 
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    AGSGraphic *note = [self.relatedFeaturesResultsArray objectAtIndex:indexPath.row];
    
    //checks whether the agree with incident field is a 1 or 0 and fills the image accordingly.
    BOOL exists;
    BOOL agree = [note attributeAsBoolForKey:@"agree_with_incident" exists:&exists];
     UIImage *image;
    if(!agree)
        image = [UIImage imageNamed:@"Disagree.png"];
    else
        image = [UIImage imageNamed:@"Agree.png"];
    
    // Set the image.
	UIImageView *imageView = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
	imageView.image = image;
    
    
    //assigns the notes text to the notes field. 
    NSString *notesText = [note attributeAsStringForKey:@"notes"];
	UILabel *label;
	
	// Set the notes text.
	label = (UILabel *)[cell viewWithTag:NOTES_TAG];
	label.text = notesText;	    
}    


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.relatedFeaturesResultsArray count] > 0)
    {
        //deselect the row first
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        //retrieve the corresponding note graphic from the array. 
        AGSGraphic *note = [self.relatedFeaturesResultsArray objectAtIndex:indexPath.row];    
        
        //make note part of the feature layer's graphics collection (it is a table, so it wont be displayed, but this needed 
        //so that field metadata is inspected when creating popup definition for the note)
        [self.incidentNotesLayer addGraphic:note];   
        
        //create a popup info. 
        AGSPopupInfo* info = [AGSPopupInfo popupInfoForGraphic:note];
        
        //divesh:set the allow edit property to yes.
        //info.allowEdit = YES;
        
        //setup the notes popup
        self.notesPopupVC = [[AGSPopupsContainerViewController alloc] initWithPopupInfo:info graphic:note usingNavigationControllerStack:NO];
        self.notesPopupVC.delegate = self;
        self.notesPopupVC.style = AGSPopupsContainerStyleDefault;
        self.notesPopupVC.modalTransitionStyle =  UIModalTransitionStyleCoverVertical;
        
        //If iPad, use a modal presentation style
        if([[AGSDevice currentDevice] isIPad])
            self.notesPopupVC.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:self.notesPopupVC animated:YES completion:nil];

        //set the popup's editing mode
        [self.notesPopupVC startEditingCurrentPopup];
    }
         
    
}

#pragma mark -  AGSPopupsContainerDelegate methods


-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didFinishEditingGraphicForPopup:(AGSPopup*)popup {
    
    long oid = [self.incidentNotesLayer objectIdForFeature:popup.graphic];
	if (oid > 0){
		//feature has a valid objectid, this means it exists on the server
        //and we simply update the exisiting feature
		[self.incidentNotesLayer updateFeatures:[NSArray arrayWithObject:popup.graphic]];
    } else {
		//objectid does not exist, this means we need to add it as a new feature
		[self.incidentNotesLayer addFeatures:[NSArray arrayWithObject:popup.graphic]];
        
	}
    
    //Tell the user edits are being saved int the background
    self.loadingView = [LoadingView loadingViewInView:self.notesPopupVC.view withText:@"Saving Notes..."];    
    
}


- (void)popupsContainer:(id) popupsContainer didCancelEditingGraphicForPopup:(AGSPopup *) popup {
    
    //dismiss the popups view controller
    [self dismissViewControllerAnimated:YES completion:nil];

    self.notesPopupVC = nil;
}

#pragma mark - AGSFeatureLayerQueryDelegate methods

- (void)featureLayer:(AGSFeatureLayer *) featureLayer operation:(NSOperation *) op didFailQueryRelatedFeaturesWithError:(NSError *) error{
    [self.loadingView removeView];
    [self warnUserOfErrorWithMessage:@"Could not perform query. Please try again"];
    NSLog(@"Error querying notes : %@", error);
}

- (void)featureLayer:(AGSFeatureLayer *) featureLayer operation:(NSOperation *) op didQueryRelatedFeaturesWithResults:(NSDictionary *) relatedFeatures {
    
    //remove the loading view
    [self.loadingView removeView];    
    
    //if the related records already exist we fill the related feature array with the features from the dictionary's result set. 
    if([relatedFeatures count]>0){
        NSLog(@"Yes, we have related records for this incident");
        AGSFeatureSet *resultsSet = [relatedFeatures objectForKey:self.incidentOID];
        self.relatedFeaturesResultsArray  =  [[NSMutableArray alloc] initWithArray:resultsSet.features];
    }   
    else
        self.relatedFeaturesResultsArray  =  [[NSMutableArray alloc] init];
    
    [self.tableView reloadData]; 
}

#pragma mark - AGSFeatureLayerEditingDelegate methods

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults{
    
    [self.loadingView removeView];
    
    if([editResults.addResults count]>0){
        //we were adding a new feature
        AGSEditResult* result = (AGSEditResult*)[editResults.addResults objectAtIndex:0];
        if(!result.success){
            //Inform user
            [self warnUserOfErrorWithMessage:@"Could not add feature. Please try again"];
        }
        else
        {            
            //also update the local features array for the table view. 
            [self.relatedFeaturesResultsArray addObject:self.notesPopupVC.currentPopup.graphic];
            
            //dismiss the popup view controller
            [self dismissViewControllerAnimated:YES completion:nil];

            self.notesPopupVC = nil;  
        }
        
    }else if([editResults.updateResults count]>0){
        //we were updating a feature
        AGSEditResult* result = (AGSEditResult*)[editResults.updateResults objectAtIndex:0];
        if(!result.success){
            //Inform user
            [self warnUserOfErrorWithMessage:@"Could not update feature. Please try again"];
        }
        else
        {            
            //dismiss the popup view controller
            [self dismissViewControllerAnimated:YES completion:nil];

            self.notesPopupVC = nil;  
        }
    }else if([editResults.deleteResults count]>0){
        AGSEditResult* result = (AGSEditResult*)[editResults.deleteResults objectAtIndex:0];
        if(!result.success){
            //Delete operation failed. Inform user
            [self warnUserOfErrorWithMessage:@"Could not delete feature. Please try again"];
        }
        else
        {
            //also update the local features array for the table view.
            [self.relatedFeaturesResultsArray removeObjectAtIndex:self.indexPathForDeleteOperation.row];
        }
    }
    
    //reload the tableview to show new data. 
    [self.tableView reloadData];
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailFeatureEditsWithError:(NSError *)error{
    NSLog(@"Could not commit edits because: %@", [error localizedDescription]);    
    [self.loadingView removeView];
    [self warnUserOfErrorWithMessage:@"Could not save edits. Please try again"];
}




#pragma mark - Action Methods

- (void)addNewNote 
{
    
    //create a new feature with the template available from the notes layer. 
    AGSGraphic *note = [self.incidentNotesLayer featureWithTemplate:[self.incidentNotesLayer.templates objectAtIndex:0]];
    
    //set the relevant attributes
    //we are setting the ID of  source incident to establish  a relationship between the note  and the incident 
    [note setAttributeWithInt:[self.incidentOID intValue] forKey:@"sf_311_serviceoid"];
    
    //set the default value for the relevant fields. "Yes" for "agree_with_incident" and empty string for notes. 
    [note setAttributeWithInt:1 forKey:@"agree_with_incident"];
    [note setAttributeWithString:@"" forKey:@"notes"];
    
    //make note part of the feature layer's graphics collection (it is a table, so it wont be displayed, but this needed 
    //so that field metadata is inspected when creating popup definition for the note)
    [self.incidentNotesLayer addGraphic:note];
    
    AGSPopupInfo* info = [AGSPopupInfo popupInfoForGraphic:note];    
    AGSPopup* notePopup = [AGSPopup popupWithGraphic:note popupInfo:info];
    
    //The note will not contain any geometry information, hence, don't show user the geometry button in the popup
    notePopup.allowEditGeometry = NO;
    
    
    
    self.notesPopupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:[NSMutableArray arrayWithObject:notePopup]  usingNavigationControllerStack:NO];
    self.notesPopupVC.delegate = self;
    self.notesPopupVC.style = AGSPopupsContainerStyleDefault;
    self.notesPopupVC.modalTransitionStyle =  UIModalTransitionStyleCoverVertical;
    
    //If iPad, use a modal presentation style
    if([[AGSDevice currentDevice] isIPad])
        self.notesPopupVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.notesPopupVC animated:YES completion:nil];
    [self.notesPopupVC startEditingCurrentPopup];  
    
}

- (void)done
{
    if([self.delegate respondsToSelector:@selector(didFinishWithNotes)])
    {
        [self.delegate didFinishWithNotes];
    }
}

#pragma mark - Helper

- (void) warnUserOfErrorWithMessage:(NSString*) message {
    //Display an alert to the user  
    [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

//query the related notes of an incident
- (void)queryRelatedRecords {
    
    //Prepare the relationship query
    AGSRelationshipQuery* query = [[AGSRelationshipQuery alloc] init];
    
    //ObjectID of source feature
    query.objectIds = [NSArray arrayWithObject:self.incidentOID];
    
    //Fields of target feature
    query.outFields = [NSArray arrayWithObject:@"*"];
    
    //Relationship to query
    query.relationshipId = 1;
    
    //Only get related records. This field is necessary and would require a dummy expression to pass
    query.definitionExpression = @"1=1";
    
    //Perform query
    AGSJSONRequestOperation* op = (AGSJSONRequestOperation*) [self.incidentLayer queryRelatedFeatures:query];
    [op.state setObject:self.incidentOID forKey:@"objectid"];    
    
    //show the loading view to indicate the process
    self.loadingView = [LoadingView loadingViewInView:self.view withText:@"Querying related records..."];    
}



@end
