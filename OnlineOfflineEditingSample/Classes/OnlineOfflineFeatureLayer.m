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


#import "OnlineOfflineFeatureLayer.h"

#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface OnlineOfflineFeatureLayer ()

-(BOOL)isOnline;
-(BOOL)validNetworkConnection;

-(void)finishedWithSuccess:(NSInteger)nSuccessCount failed:(NSInteger)nFailCount;
-(void)doneFailed;    

-(void)writeFeatureLayerDefinition;
-(void)writeFeatureSet:(AGSFeatureSet *)featureSet;
-(void)writeAddedFeatures:(NSArray *)addedFeatures;
-(void)writeAddedAttachments:(NSArray *)addedAttachments;

-(NSDictionary *)readFeatureLayerDefinition;
-(NSDictionary *)readFeatureSet;
-(NSMutableArray *)readAddedFeatures;
-(NSMutableArray *)readAddedAttachments;

-(NSString *)featureSetFilename;
-(NSString *)featureLayerDefinitionFilename;
-(NSString *)addedAttachmentsFilename;

@end

static NSString *kFlDefinitionFileName = @"FeatureLayerDictionary";
static NSString *kFeatureSetFileName = @"FeatureSet";
static NSString *kAddedFeaturesFilename = @"AddedFeatures";
static NSString *kAddedAttachmentsFilename = @"AddedAttachments";

@implementation OnlineOfflineFeatureLayer

@synthesize bOnline = _bOnline;
@synthesize offlineFeaturesQueryOperation = _offlineFeaturesQueryOperation;
@synthesize addedFeaturesArray = _addedFeaturesArray;
@synthesize addedAttachmentsArrays = _addedAttachmentsArrays;
@synthesize addOfflineFeaturesOperation = _addOfflineFeaturesOperation;
@synthesize onlineOfflineDelegate = _onlineOfflineDelegate;
@synthesize operations = _operations;

- (id)initWithURL:(NSURL *)url mode:(AGSFeatureLayerMode)mode online:(BOOL)online
{
    if (self = [super init]){
        
        self.bOnline = online;
        self.addedFeaturesArray = [NSMutableArray array];
        self.addedAttachmentsArrays = [NSMutableArray array];
        
        if (self.bOnline)
        {
            [super initWithURL:url mode:mode];
            
            //
            //check and see if we have feature edits to post
            //
            //...
            self.addedFeaturesArray = [self readAddedFeatures];
            self.addedAttachmentsArrays = [self readAddedAttachments];
            
        }
        else {
            //restore features from saved feature store...
            
            NSDictionary *featureLayerDefinition = [self readFeatureLayerDefinition];
            NSDictionary *featureSetDictionary = [self readFeatureSet];
            
            if (!featureSetDictionary || !featureLayerDefinition)
            {
                //we're offline, but have no saved feature set or definition
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Offline Features"
                                                                message:@"There is no network connection and there are no offline features to use."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
            else{
                //init with our saved information
                [self initWithLayerDefinitionJSON:featureLayerDefinition featureSetJSON:featureSetDictionary];
            }
        }
	}
    
	return self;
}

- (id)initWithURL:(NSURL *)url mode:(AGSFeatureLayerMode)mode;
{
    //determine whether we're online or not by checking the network connection
    return [self initWithURL:url mode:mode online:[self validNetworkConnection]];
}

+ (id)featureServiceLayerWithURL:(NSURL *)url mode:(AGSFeatureLayerMode)mode
{
    return [[[OnlineOfflineFeatureLayer alloc] initWithURL:url mode:mode] autorelease];
}

+ (id)featureServiceLayerWithURL:(NSURL *)url mode:(AGSFeatureLayerMode)mode online:(BOOL)online
{
    return [[[OnlineOfflineFeatureLayer alloc] initWithURL:url mode:mode online:online] autorelease];
}

#pragma mark -
#pragma mark Offline Use

-(void)prepForOfflineUse:(AGSEnvelope *)extent
{
    //if we're already offline, return
    if (!self.bOnline)
        return;
    
    //create query based on extent    
    AGSQuery *query = [AGSQuery query];
    query.geometry = extent;
    query.spatialRelationship = AGSSpatialRelationshipEnvelopeIntersects;
    
    //query features that intersect the visible extent
    self.queryDelegate = self;
    self.offlineFeaturesQueryOperation = [self queryFeatures:query];
    
    //in delegate method, store featureset and feature layer definition...
}

-(void)addOfflineFeature:(AGSGraphic *)feature withAttachments:(NSArray *)attachments
{
    //store the feature in our array
    [self.addedFeaturesArray addObject:feature];
    
    //addedAttachmentsArrays is an array of arrays
    [self.addedAttachmentsArrays addObject:attachments];
    
    //add the features to the feature layer so they get displayed
    [self addGraphic:feature];
    
    //write the array to disk...
    [self writeAddedFeatures:self.addedFeaturesArray];
    [self writeAddedAttachments:self.addedAttachmentsArrays];
}

-(void)commitOfflineFeatures
{
    //the features have already been set up, so just add them...
    //but first, set ourself as the editing delegate so we can get operation results...
    self.editingDelegate = self;    
    
    //add all the grahics that was created in teh offline layer to the new online layer here
    [self addGraphics:self.addedFeaturesArray]; 
    
   
    //post the features to the server.
    [self addFeatures:self.addedFeaturesArray];
}

#pragma mark -
#pragma mark AGSFeatureLayerEditingDelegate

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults{
	// called when feature layer is done with feature edits (in this case, done adding the feature)
	
	// set operation to nil to release it
    self.addOfflineFeaturesOperation = nil;
	
    int nFailCount = 0;
    int nSucceedCount = 0;
    for (AGSEditResult *addResult in editResults.addResults) {
        if (!addResult.success)
        {
            nFailCount++;
        }
        else {
            // if added feature, set the objectId
            NSLog(@"added feature: %d",addResult.objectId);
            
            //get attachment array for this feature.  This will be an empty array
            //if there are no attachments for this feature.
            NSArray *attachmentArray = [self.addedAttachmentsArrays objectAtIndex:0];
            if ([attachmentArray count] > 0){
                // add the attachments
                for (int i = 0; i < [attachmentArray count]; i++){
                    id file = [attachmentArray objectAtIndex:i];
                    if ([file isKindOfClass:[NSURL class]]){
                        NSData *data = [NSData dataWithContentsOfURL:file];
                        [self.operations addObject:[self addAttachment:addResult.objectId data:data filename:[[file absoluteString]lastPathComponent] ]];
                    }
                    else if ([file isKindOfClass:[NSString class]]){
                        [self.operations addObject:[self addAttachment:addResult.objectId filepath:file]];
                    }
                }
            }
            
            nSucceedCount++;
        }
        
        //whether we successfully added the feature or not, we need
        //to remove the attachment array from the self.addedAttachmentsArrays
        [self.addedAttachmentsArrays removeObjectAtIndex:0];
    }

    [self finishedWithSuccess:nSucceedCount failed:nFailCount];
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailFeatureEditsWithError:(NSError *)error{
	// called when the feature layer fails to perform the feature edits (in the case fails to add the feature)

    // set operation to nil to release it
    self.addOfflineFeaturesOperation = nil;
	
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
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailAttachmentEditsWithError:(NSError *)error{
	// called when the feature layer fails to add the attachment
	
	NSLog(@"error adding attachment: %@", error.description);
	
	// remove the operation
	[self.operations removeObject:op];
}

-(void)finishedWithSuccess:(NSInteger)nSuccessCount failed:(NSInteger)nFailCount{
	// called when we are done and the feature was added successfully
	
	// show an alert
	UIAlertView *alertView = [[[UIAlertView alloc]initWithTitle:@"Trail Added"
														message:[NSString stringWithFormat:@"You have successfully added %i trail(s) that were collected offline.  %i trail(s) failed to add.", nSuccessCount, nFailCount]
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil]autorelease];
	[alertView show];
}

-(void)doneFailed{
	// called when we are done and the feature was not successfully added

	// show an alert
	UIAlertView *alertView = [[[UIAlertView alloc]initWithTitle:@"Error"
														message:@"There was an error adding the trail."
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil]autorelease];
	[alertView show];
}

#pragma mark -
#pragma mark AGSFeatureLayerQueryDelegate

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didQueryFeaturesWithFeatureSet:(AGSFeatureSet *)featureSet
{    
    //set the operation to nil
    self.offlineFeaturesQueryOperation = nil;
    
	if (featureSet.features.count == 0)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Features"
														message:@"No features were found in the current extent."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	else {
        //save featureSet to disk/user defaults
        [self writeFeatureSet:featureSet];
        
        //save flDefinition to disk/user defaults
        [self writeFeatureLayerDefinition];
                
        //If we needed to view atachments while offline, this is where we
        //would would grab the attachments, if any, for
        //features in the feature set and store those as well.
	}
    
    if([self.onlineOfflineDelegate respondsToSelector:@selector(prepForOfflineUseCompleted:)])
    {
        [self.onlineOfflineDelegate prepForOfflineUseCompleted:YES];
    }
    
}

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailQueryFeaturesWithError:(NSError *)error
{
    self.offlineFeaturesQueryOperation = nil;
    
    NSString *errorMessage = [NSString stringWithFormat:@"Unable to perform query.  Check the syntax and try again. %@", [error localizedDescription]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    if([self.onlineOfflineDelegate respondsToSelector:@selector(prepForOfflineUseCompleted:)])
    {
        [self.onlineOfflineDelegate prepForOfflineUseCompleted:NO];
    }
}

#pragma mark -
#pragma mark Private Methods

-(BOOL)isOnline
{    
    return self.bOnline;
}

#pragma mark -
#pragma mark Write

-(void)writeFeatureLayerDefinition
{
    NSError *error = nil;
    NSString *flDefinition = [[self encodeToJSON] ags_JSONRepresentation];
    
	BOOL bSuccess = [flDefinition writeToFile:[self featureLayerDefinitionFilename]
                                   atomically:YES
                                     encoding:NSUnicodeStringEncoding
                                        error:&error];
    
    NSLog(@"flDefinition %@", [self featureLayerDefinitionFilename]);
    NSLog(@"Success %@", bSuccess ? @"YES" : @"NO");
}

-(void)writeFeatureSet:(AGSFeatureSet *)featureSet
{
    NSError *error = nil;
    NSString *featureSetDictionary = [[featureSet encodeToJSON] ags_JSONRepresentation];
    
	BOOL bSuccess = [featureSetDictionary writeToFile:[self featureSetFilename]
                                           atomically:YES
                                             encoding:NSUnicodeStringEncoding
                                                error:&error];
    
    NSLog(@"writeFeatureSet %@", [self featureSetFilename]);
    NSLog(@"Success %@", bSuccess ? @"YES" : @"NO");
}

-(void)writeAddedFeatures:(NSArray *)addedFeatures
{
    if (addedFeatures && [addedFeatures count] > 0)
    {
        NSError *error = nil;
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        [AGSJSONUtility encodeToDictionary:json withKey:@"addedFeatures" AGSCodingArray:self.addedFeaturesArray];
        
        NSString *addedFeaturesString = [json ags_JSONRepresentation];        
        BOOL bSuccess = [addedFeaturesString writeToFile:[self addedFeaturesFilename]
                                               atomically:YES
                                                 encoding:NSUnicodeStringEncoding
                                                    error:&error];
        
        NSLog(@"writeAddedFeatures %@", [self addedFeaturesFilename]);
        NSLog(@"Success %@", bSuccess ? @"YES" : @"NO");        
    }
}

-(void)writeAddedAttachments:(NSArray *)addedAttachments
{
    if (addedAttachments && [addedAttachments count] > 0)
    {
        NSError *error = nil;
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        [json setObject:addedAttachments forKey:@"addedAttachments"];
        
        NSString *addedAttachmentsString = [json ags_JSONRepresentation];        
        BOOL bSuccess = [addedAttachmentsString writeToFile:[self addedAttachmentsFilename]
                                                 atomically:YES
                                                   encoding:NSUnicodeStringEncoding
                                                      error:&error];
        
        NSLog(@"writeAddedAttachments %@", [self addedAttachmentsFilename]);
        NSLog(@"Success %@", bSuccess ? @"YES" : @"NO");        
    }
}

#pragma mark -
#pragma mark Read

-(NSDictionary *)readFeatureLayerDefinition
{
    NSError *error = nil;
    NSDictionary *flDefinition = nil;
    
    NSString *filename = [self featureLayerDefinitionFilename];    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
		NSString *flDefinitionString = [NSString stringWithContentsOfFile:filename encoding:NSUnicodeStringEncoding error:&error];
        
        flDefinition = (NSDictionary *)[flDefinitionString ags_JSONValue];
    }        
    
	return flDefinition;
}

-(NSDictionary *)readFeatureSet
{
    NSError *error = nil;
    NSDictionary *featureSetDictionary = nil;
    NSString *filename = [self featureSetFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
		NSString *featureSetString = [NSString stringWithContentsOfFile:filename encoding:NSUnicodeStringEncoding error:&error];
        
        featureSetDictionary = (NSDictionary *)[featureSetString ags_JSONValue];
    }        
    
    return featureSetDictionary;
}

-(NSMutableArray *)readAddedFeatures
{
    NSError *error = nil;
    NSMutableArray *addedFeatures = nil;
    NSString *filename = [self addedFeaturesFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
		NSString *addedFeaturesString = [NSString stringWithContentsOfFile:filename encoding:NSUnicodeStringEncoding error:&error];
        
        
        NSLog(@"Read from file ********* %@", addedFeaturesString);
        NSArray *tmpArray = [AGSJSONUtility decodeFromDictionary:[addedFeaturesString ags_JSONValue]
                                                      withKey:@"addedFeatures"
                                                    fromClass:[AGSGraphic class]];
        
        addedFeatures = [NSMutableArray arrayWithArray:tmpArray];
    }        
    
    return addedFeatures;
}

-(NSMutableArray *)readAddedAttachments
{
    NSError *error = nil;
    NSMutableArray *addedAttachments = nil;
    NSString *filename = [self addedAttachmentsFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
		NSString *addedAttachmentsString = [NSString stringWithContentsOfFile:filename encoding:NSUnicodeStringEncoding error:&error];
        
        NSArray *tmpArray = [[addedAttachmentsString ags_JSONValue] objectForKey:@"addedAttachments"];
        
        addedAttachments = [NSMutableArray arrayWithArray:tmpArray];
    }        
    
    return addedAttachments;
}

#pragma mark -
#pragma mark Filenames

-(NSString *)featureSetFilename
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:kFeatureSetFileName];
}

-(NSString *)featureLayerDefinitionFilename
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:kFlDefinitionFileName];
}

-(NSString *)addedFeaturesFilename
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:kAddedFeaturesFilename];
}

-(NSString *)addedAttachmentsFilename
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:kAddedAttachmentsFilename];
}

#pragma mark -
#pragma mark NetworkConnection

//The following was adapted from the Rechability Apple sample
-(BOOL) validNetworkConnection
{
    struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    
    SCNetworkReachabilityFlags flags = 0;
    Boolean bFlagsValid = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    
    if (!bFlagsValid)
        return NO;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
		// if target host is not reachable
		return NO;//NotReachable;
	}
    
	BOOL retVal = NO;
	
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		// if target host is reachable and no connection is required
		//  then we'll assume (for now) that your on Wi-Fi
		retVal = YES;
	}
	
	
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            retVal = YES;
        }
    }
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		// ... but WWAN connections are OK if the calling application
		//     is using the CFNetwork (CFSocketStream?) APIs.
		retVal = YES;
	}
    
	return retVal;
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc
{    
    if (self.offlineFeaturesQueryOperation)
    {
        [self.offlineFeaturesQueryOperation cancel];
        self.offlineFeaturesQueryOperation = nil;
    }
    
    if (self.addOfflineFeaturesOperation)
    {
        [self.addOfflineFeaturesOperation cancel];
        self.addOfflineFeaturesOperation = nil;
    }
    
    [self.operations makeObjectsPerformSelector:@selector(cancel)];
    self.operations = nil;
    
    self.addedFeaturesArray = nil;
    self.addedAttachmentsArrays = nil;
    self.operations = nil;
    
    [super dealloc];
}

@end
