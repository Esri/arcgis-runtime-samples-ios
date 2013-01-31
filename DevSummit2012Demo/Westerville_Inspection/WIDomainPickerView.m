/*
 WIDomainPickerView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIDomainPickerView.h"
#import "WIInspection.h"
#import "WIAttributeUtility.h"
#import "WIIndexCardTableViewCell.h"
#import <ArcGIS/ArcGIS.h>

@interface WIDomainPickerView ()

@property (nonatomic, strong) WIInspection                 *inspection;

//editing subtype field
@property (nonatomic, strong) NSMutableArray                *templates;
@property (nonatomic, strong) NSMutableArray                *templateTypeValues;
@property (nonatomic, strong, readwrite) AGSFeatureTemplate *templateChosen;

@property (nonatomic, strong) WIIndexCardTableView         *tableView;
@property (nonatomic, strong) UIButton                      *doneButton;

- (AGSDomain *)getDomain;
- (void)doneButtonPressed:(id)sender;

@end

@implementation WIDomainPickerView

@synthesize delegate            = _delegate;
@synthesize inspection          = _inspection;
@synthesize fieldOfInterest     = _fieldOfInterest;
@synthesize selectedValue       = _selectedValue;

@synthesize templates           = _templates;
@synthesize templateTypeValues  = _templateTypeValues;
@synthesize templateChosen      = _templateChosen;

@synthesize doneButton          = _doneButton;
@synthesize tableView           = _tableView;


- (id)initWithFrame:(CGRect)frame withInspection:(WIInspection *)inspection fieldOfInterest:(AGSPopupFieldInfo *)fieldInfo
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.inspection         = inspection;
        self.fieldOfInterest    = fieldInfo;
        
        //Figure out values to populate list with
        AGSDomain *domain = [self getDomain];
        
        //Do we actually have a domain?
        if (domain != nil)
        {
            if ([domain isKindOfClass:[AGSCodedValueDomain class]])
            {
                if (!self.selectedValue || self.selectedValue == (id)[NSNull null])
                {
                    AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
                    AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:0];
                    
                    self.selectedValue = codedValue.code;
                }
                
                //let domainCollector's tableview handle setting self.value
            }
        }
        
        //No domain... See if typeID field is our field
        else if([self.inspection.attributeUtility.featureLayer.typeIdField isEqualToString:self.fieldOfInterest.fieldName])
        {
            //might need to use custom pick list if a feature type is determined by the type ID field on a feature layer
            self.templates = [NSMutableArray array];
            self.templateTypeValues = [NSMutableArray array];
            
            NSInteger nTypesCount = self.inspection.attributeUtility.featureLayer.types.count;
            if (nTypesCount > 0){
                for (AGSFeatureType *ft in self.inspection.attributeUtility.featureLayer.types){
                    for (AGSFeatureTemplate *t in ft.templates) {
                        [self.templates addObject:t];
                        // try to pull value from attributes first, in case for some
                        // reason it is different than typeId
                        id ttv = [t.prototype attributeForKey:self.fieldOfInterest.fieldName];
                        if (!ttv){
                            ttv = ft.typeId;
                        }
                        [self.templateTypeValues addObject:ttv];
                    }
                }
            }
            
            
            //If we havent' set the selected value yet, populate with the first templated value
            if (!self.selectedValue || self.selectedValue == (id)[NSNull null]){
                self.selectedValue = [self.templateTypeValues objectAtIndex:0];
            }
        }

        
        //User Interface
        self.backgroundColor = [UIColor whiteColor];
        
        WIIndexCardTableView   *tv = [[WIIndexCardTableView alloc] initWithFrame:self.bounds datasource:self];
        tv.indexCardDelegate = self;
        self.tableView = tv;
                
        //Done Button
        CGFloat margin = 5.0f;
        CGFloat buttonWidth = 35.0f;
        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneButton.frame = CGRectMake(frame.size.width - (margin + buttonWidth), margin, buttonWidth, buttonWidth);
        [self.doneButton setImage:[UIImage imageNamed:@"cancelButton.png"] forState:UIControlStateNormal];
        [self.doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.tableView];
        [self addSubview:self.doneButton];
    }
    
    return self;
}

#pragma mark -
#pragma mark Button Interaction
- (void)doneButtonPressed:(id)sender
{
    if([self.delegate respondsToSelector:@selector(domainPickerViewDidFinish:)])
    {
        [self.delegate domainPickerViewDidFinish:self];
    }
}

#pragma mark -
#pragma mark AGSIndexCardDataSource
- (NSUInteger)numberOfRows
{
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

- (WIIndexCardTableViewCell *)indexCardTableView:(WIIndexCardTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIIndexCardTableViewCell *cell = [tv defaultRowCell];
    
    NSString *sText = @"";
    BOOL showCheckMark = NO;
    
    AGSDomain *domain = [self getDomain];    
    if ([domain isKindOfClass:[AGSCodedValueDomain class]])
    {
        AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
        AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:index];
        
        sText = codedValue.name;
        
        if ([codedValue.code isKindOfClass:[NSNumber class]])
        {
			if (self.selectedValue != [NSNull null]){
				NSNumber *numValue = (NSNumber *)self.selectedValue;
				NSNumber *codeValue = (NSNumber *)codedValue.code;
				if ([numValue intValue] == [codeValue intValue])
				{
					showCheckMark = YES;
				}
			}
        }
        else if ([codedValue.code isKindOfClass:[NSString class]])
        {
			if (self.selectedValue != [NSNull null]){
				NSString *strValue = (NSString *)self.selectedValue;
				NSString *codeValue = (NSString *)codedValue.code;
				if ([strValue isEqualToString:codeValue])
				{
					showCheckMark = YES;
				}
			}
        }
    }
    else if(self.templateTypeValues){
		AGSFeatureTemplate *t = [self.templates objectAtIndex:index];
		id ttv = [self.templateTypeValues objectAtIndex:index];
		if ([self.selectedValue isEqual:ttv]){
			showCheckMark = YES;
		}
        sText = t.name;
    }
    
    cell.nameLabel.text = sText;
    cell.selectedRow = showCheckMark;
    
    return cell;
}

#pragma mark -
#pragma mark AGSIndexCardTableViewDelegate
- (void)indexCardTableView:(WIIndexCardTableView *)tv didSelectRowAtIndex:(NSUInteger)index
{    
    AGSDomain *domain = [self getDomain];
    if ([domain isKindOfClass:[AGSCodedValueDomain class]])
    {
        AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
        AGSCodedValue *codedValue = (AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:index];
        
        //set the new coded value
        self.selectedValue = codedValue.code;
    }
    else if(self.templateTypeValues)
    {
        self.selectedValue = [self.templateTypeValues objectAtIndex:index];
        self.templateChosen = [self.templates objectAtIndex:index];
    }
    
    //redraw the table to get the new checkmark
    [tv reloadData];
    
    //automatically close index card
    [self doneButtonPressed:self.doneButton];
}

#pragma mark -
#pragma mark Private Methods
- (AGSDomain *)getDomain
{
    AGSDomain *domain = [self.inspection.attributeUtility domainForFieldInfo:self.fieldOfInterest];
    
    if (self.inspection.attributeUtility.featureType)
    {
        //do this so we can show domains coming from the feature type and not the field    
        AGSDomain *featureTypeDomain = [self.inspection.attributeUtility.featureType.domains objectForKey:self.fieldOfInterest.fieldName];
        if (featureTypeDomain != nil && featureTypeDomain != (id)[NSNull  null])
        {
            domain = featureTypeDomain;
        }
    }
    
    return domain;
}

@end
