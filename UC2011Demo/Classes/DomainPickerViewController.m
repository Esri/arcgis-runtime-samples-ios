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

#import "DomainPickerViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AttributeUtility.h"
#import "DomainPickerTableViewCell.h"

//private methods
@interface DomainPickerViewController () 

-(AGSDomain *)getDomain;

@end


@implementation DomainPickerViewController

@synthesize postItNoteImageView = _postItNoteImageView;
@synthesize tableView = _tableView;
@synthesize fieldInfo = _fieldInfo;
@synthesize attributeUtility = _attributeUtility;

@synthesize value = _value;
@synthesize delegate = _delegate;

@synthesize templates = _templates;
@synthesize templateTypeValues = _templateTypeValues;
@synthesize templateChosen = _templateChosen;

-(id)initWithFieldInfo:(AGSPopupFieldInfo *)fi andAttributeUtility:(AttributeUtility *)attributeUtility
{
    self = [super initWithNibName:@"DomainPickerViewController" bundle:nil];
    
    if (self) {
        self.fieldInfo = fi;
        self.attributeUtility = attributeUtility;
        self.value = nil;
    }
    
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.postItNoteImageView.image = [UIImage imageNamed:@"yellow_post_it.png"];
    
    
    //figure out domain values
    AGSDomain *domain = [self getDomain];
    
    if (domain != nil)
    {
        //show domain collector
        //but we might need to switch on domain type...
        if ([domain isKindOfClass:[AGSCodedValueDomain class]])
        {
            if (!self.value || self.value == (id)[NSNull null])
            {
                AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
                AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:0];
                
                self.value = codedValue.code;
            }
            
            //let domainCollector's tableview handle setting self.value
        }
    }
    else if([self.attributeUtility.featureLayer.typeIdField isEqualToString:self.fieldInfo.fieldName])
    {
		//might need to use custom pick list if a feature type is determined by the type ID field on a feature layer
		self.templates = [NSMutableArray array];
		self.templateTypeValues = [NSMutableArray array];
		
		NSInteger nTypesCount = self.attributeUtility.featureLayer.types.count;
		if (nTypesCount > 0){
			for (AGSFeatureType *ft in self.attributeUtility.featureLayer.types){
				for (AGSFeatureTemplate *t in ft.templates) {
					[self.templates addObject:t];
					// try to pull value from attributes first, in case for some
					// weird reason it is different than typeId
					id ttv = [t.prototype attributeForKey:self.fieldInfo.fieldName];
					if (!ttv){
						ttv = ft.typeId;
					}
					[self.templateTypeValues addObject:ttv];
				}
			}
		}
		
        
        if (!self.value || self.value == (id)[NSNull null]){
            self.value = [self.templateTypeValues objectAtIndex:0];
        }
    }
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSInteger nRowCount = 0;
    
    AGSDomain *domain = [self getDomain];    
    if ([domain isKindOfClass:[AGSCodedValueDomain class]])
    {
        AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
        nRowCount = [codedValueDomain.codedValues count];
    }
    else if(self.templateTypeValues)
    {
        nRowCount = self.templateTypeValues.count;
    }
    
    return nRowCount;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (DomainPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DomainPickerTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSString *sText = @"";
    BOOL showCheckMark = NO;
    
    AGSDomain *domain = [self getDomain];    
    if ([domain isKindOfClass:[AGSCodedValueDomain class]])
    {
        AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
        AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:indexPath.row];
        
        sText = codedValue.name;
        
        if ([codedValue.code isKindOfClass:[NSNumber class]])
        {
			if (self.value != [NSNull null]){
				NSNumber *numValue = (NSNumber *)self.value;
				NSNumber *codeValue = (NSNumber *)codedValue.code;
				if ([numValue intValue] == [codeValue intValue])
				{
					showCheckMark = YES;
				}
			}
        }
        else if ([codedValue.code isKindOfClass:[NSString class]])
        {
			if (self.value != [NSNull null]){
				NSString *strValue = (NSString *)self.value;
				NSString *codeValue = (NSString *)codedValue.code;
				if ([strValue isEqualToString:codeValue])
				{
					showCheckMark = YES;
				}
			}
        }
    }
    else if(self.templateTypeValues){
		AGSFeatureTemplate *t = [self.templates objectAtIndex:indexPath.row];
		id ttv = [self.templateTypeValues objectAtIndex:indexPath.row];
		if ([self.value isEqual:ttv]){
			showCheckMark = YES;
		}
        sText = t.name;
    }
    
    DomainPickerTableViewCell *domainCell = (DomainPickerTableViewCell *)cell;
    domainCell.domainValue.text = sText;
    domainCell.checkMark.hidden = !showCheckMark;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AGSDomain *domain = [self getDomain];
    if ([domain isKindOfClass:[AGSCodedValueDomain class]])
    {
        AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
        AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:indexPath.row];
        
        //set the new coded value
        self.value = codedValue.code;
    }
    else if(self.templateTypeValues)
    {
        self.value = [self.templateTypeValues objectAtIndex:indexPath.row];
        self.templateChosen = [self.templates objectAtIndex:indexPath.row];
    }
    
    //redraw the table to get the new checkmark
    [tableView reloadData];
}


#pragma mark -
#pragma mark Button Interaction

-(IBAction)doneButtonPressed
{
    if([self.delegate respondsToSelector:@selector(domainPickerDidFinish:)])
    {
        [self.delegate domainPickerDidFinish:self];
    }
}

#pragma mark -
#pragma mark Internal

-(AGSDomain *)getDomain
{
    AGSDomain *domain = [self.attributeUtility domainForFieldInfo:self.fieldInfo];
    
    if (self.attributeUtility.featureType)
    {
        //do this so we can show domains coming from the feature type and not the field    
        AGSDomain *featureTypeDomain = [self.attributeUtility.featureType.domains objectForKey:self.fieldInfo.fieldName];
        if (featureTypeDomain != nil && featureTypeDomain != (id)[NSNull  null])
        {
            domain = featureTypeDomain;
        }
    }
    
    return domain;
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


#pragma mark -
#pragma mark Apple Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];

    self.tableView = nil;
    self.postItNoteImageView = nil;
}




@end
