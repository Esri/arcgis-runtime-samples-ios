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

#import "AttributeUtility.h"
#import <ArcGIS/ArcGIS.h>

@implementation AttributeUtility

@synthesize popup = _popup;
@synthesize featureType = _featureType;
@synthesize featureLayer = _featureLayer;
@synthesize fieldNamesDictionary = _fieldNamesDictionary;
@synthesize fieldDictionary = _fieldDictionary;
@synthesize fieldInfosDictionary = _fieldInfosDictionary;


//default initializer
-(id)initWithPopup:(AGSPopup *)pi;
{
    self = [super init];
    if(self)
    {
        self.popup = pi;
        
        // set featureLayer property and featureType if possible
		if ([self.popup.graphic.layer isKindOfClass:[AGSFeatureLayer class]]){
			self.featureLayer = (AGSFeatureLayer *)self.popup.graphic.layer;
			
			if (self.featureLayer.typeIdField){
				id ftVal = [self.popup.graphic attributeForKey:self.featureLayer.typeIdField];
				for (AGSFeatureType *ft in self.featureLayer.types){
					if ([ft.typeId isEqual:ftVal]){
						self.featureType = ft;
						break;
					}
				}
			}
		}
    }
    
    return self;
}

#pragma mark -
#pragma mark Template Strings

//Method replaces all occurrences of {attribute} (where attribute is an attribute name),
//with the value of that attribute
-(NSString *)stringByApplyingTemplatesToString:(NSString *)aString
{
    NSString *dollarString = [aString stringByReplacingOccurrencesOfString:@"{" withString:@"${"];
    
    if (NSNotFound == [dollarString rangeOfString:@"${"].location) {
        return dollarString;
    }
    
    NSMutableString *result = [dollarString mutableCopy];
    
    for (AGSField *field in self.featureLayer.fields) {
    
        NSString *keyTemplate = [[NSString alloc] initWithFormat:@"${%@}", field.name];
        [result replaceOccurrencesOfString:keyTemplate 
                                withString:[self attributeStringForField:field]
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0, [result length])];
    }
    
    return result;
}


//Helper Method. Returns the string value for the input AGSField
-(NSString *)attributeStringForField:(AGSField *)field
{
    //get the attribute for the given field name from the feature attributes
    id value = [self.popup.graphic attributeForKey:field.name];
    
    //if value is null, return an empty string representation
    if (value == [NSNull null] || value == nil)
    {
        return @"";
    }
    
    //get field type:
    AGSFieldType fieldType = field.type;
    
    //get the field info for the 
    AGSPopupFieldInfo *fi = [self.fieldInfosDictionary objectForKey:[NSValue valueWithNonretainedObject:field]];
    
    NSString *attributeString = @"";
    
    //prep for domain check.  If we don't have a featureType domain, then
    //check for a field.domain.
    AGSDomain *domain = nil;
    if (self.featureType)
    {
        domain = [self.featureType.domains objectForKey:field.name];
    }
    
    if (!domain || domain == (id)[NSNull  null])
    {
        domain = field.domain;
    }
    
	if (domain != nil && domain != (id)[NSNull  null])
    {
        if ([domain isKindOfClass:[AGSCodedValueDomain class]])
        {
            AGSCodedValueDomain *codedValueDomain = (AGSCodedValueDomain *)domain;
            if (!value )
            {
                //we have no value, get the first one, but use the name for a pretty display
                AGSCodedValue *codedValue = ((AGSCodedValue *)[codedValueDomain.codedValues objectAtIndex:0]);
                value = codedValue.name;
            }
            else {
                //we have value, but it's actually the code, so find the corresponding
                //prety name and use that instead.
                for (AGSCodedValue *codedValue in codedValueDomain.codedValues) {
                    
                    if ([codedValue.code isKindOfClass:[NSNumber class]])
                    {
                        NSNumber *numValue = (NSNumber *)value;
                        NSNumber *codeValue = (NSNumber *)codedValue.code;
                        if ([numValue doubleValue] == [codeValue doubleValue])
                        {
                            value = codedValue.name;
							break;
                        }
                    }
                    else if ([codedValue.code isKindOfClass:[NSString class]])
                    {
                        if ([value isKindOfClass:[NSNumber class]]) {
                            value = [NSString stringWithFormat:@"%@", value];
                            
                        }
                        
                        NSString *numValue = (NSString *)value;
                        NSString *codeValue = (NSString *)codedValue.code;
                        if ([numValue isEqualToString:codeValue])
                        {
                            value = codedValue.name;
							break;
                        }
                    }
                }                
            }
            
            attributeString = [NSString stringWithFormat:@"%@", value];
        }
        else if ([domain isKindOfClass:[AGSRangeDomain class]])
        {
            AGSRangeDomain *rangeDomain = (AGSRangeDomain *)domain;
            if (!value )
            {
                value = [NSNumber numberWithFloat:([rangeDomain.maxValue floatValue] - [rangeDomain.minValue floatValue]) / 2.0];
                attributeString = [((NSNumber *)value) stringValue];
            }
            else if ([value isKindOfClass:[NSNumber class]])
            {
                attributeString = [((NSNumber *)value) stringValue];
            }
        }
    }
    else if ([self.featureLayer.typeIdField isEqualToString:fi.fieldName]){	
		NSInteger nTypesCount = self.featureLayer.types.count;
		if (nTypesCount > 0){
			for (AGSFeatureType *ft in self.featureLayer.types){
				for (AGSFeatureTemplate *t in ft.templates) {
					// try to pull value from attributes first, in case for some
					// weird reason it is different than typeId
					id ttv = [t.prototype attributeForKey:fi.fieldName];
					if (!ttv){
						ttv = ft.typeId;
					}
					if ([ttv isEqual:value]){
						attributeString = t.name;
						break;
					}
				}
			}
		}
    }
    else if (fieldType == AGSFieldTypeSmallInteger ||
             fieldType == AGSFieldTypeInteger)
    {   
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        
        if (fi.showDigitSeparator) {
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        }
        
        attributeString = [formatter stringFromNumber:(NSNumber *)value];
                
    }
    else if(fieldType == AGSFieldTypeString)
    {
        if (value == [NSNull null])
        {
            value = @"";
        }
        
        attributeString = [NSString stringWithFormat:@"%@", value];
    }
    //Need to use the information from the FieldInfo formatter
    else if(fieldType == AGSFieldTypeSingle ||
            fieldType == AGSFieldTypeDouble)
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        
        NSNumber *numberValue = (NSNumber *)value;
        if ([value isKindOfClass:[NSString class]]) {
            numberValue = [formatter numberFromString:(NSString *)value];
        }
        
        if (fi.showDigitSeparator) {
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        }
        
        [formatter setMaximumFractionDigits:fi.numDecimalPlaces];
                
        attributeString = [formatter stringFromNumber:numberValue];
        
    }
    else if(fieldType == AGSFieldTypeDate){
        NSDate* createdDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)value doubleValue] / 1000.0];
		attributeString = [self stringForDate:createdDate format:fi.dateFormat];
    }
    
    if (!attributeString)
        attributeString = @"";
    
    return attributeString;
}

-(NSString*)stringForDate:(NSDate*)date format:(AGSPopupFieldInfoDateFormat)format{
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	if(format == AGSPopupFieldInfoDateFormatShortDate)
	{
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
	else if(format == AGSPopupFieldInfoDateFormatLongMonthDayYear)
	{
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	else if(format == AGSPopupFieldInfoDateFormatShortMonthYear)
	{
		[dateFormatter setDateFormat:@"MMM yyyy"];
	}
	else if(format == AGSPopupFieldInfoDateFormatDayShortMonthYear)
	{
		[dateFormatter setDateFormat:@"d, MMM yyyy"];
	}
	else if(format == AGSPopupFieldInfoDateFormatLongDate)
	{
		[dateFormatter setDateStyle:NSDateFormatterFullStyle];
	}
	else if(format == AGSPopupFieldInfoDateFormatShortDateShortTime)
	{
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	else if(format == AGSPopupFieldInfoDateFormatShortDateShortTime24)
	{
		[dateFormatter setDateFormat:@"M/d/yyyy H:m"];
	}
	else if(format == AGSPopupFieldInfoDateFormatLongMonthYear)
	{
		[dateFormatter setDateFormat:@"MMMM yyyy"];
	}
	else if(format == AGSPopupFieldInfoDateFormatYear)
	{
		[dateFormatter setDateFormat:@"yyyy"];
	}
	//catch all. Probably shouldn't get here ever though
	else {
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
	}
	
	return [dateFormatter stringFromDate:date];
}

-(BOOL)isAStringField:(AGSField *)field
{
    //get field type:
    AGSFieldType fieldType = field.type;
        
    //prep for domain check.  If we don't have a featureType domain, then
    //check for a field.domain.
    AGSDomain *domain = nil;
    if (self.featureType)
    {
        domain = [self.featureType.domains objectForKey:field.name];
    }
    
    if (!domain || domain == (id)[NSNull  null])
    {
        domain = field.domain;
    }
    
    return (domain == nil && (fieldType == AGSFieldTypeString));
}

-(BOOL)isANumberField:(AGSField *)field
{
    //get field type:
    AGSFieldType fieldType = field.type;
    
    //prep for domain check.  If we don't have a featureType domain, then
    //check for a field.domain.
    AGSDomain *domain = nil;
    if (self.featureType)
    {
        domain = [self.featureType.domains objectForKey:field.name];
    }
    
    if (!domain || domain == (id)[NSNull  null])
    {
        domain = field.domain;
    }
    
    return (domain == nil && (fieldType == AGSFieldTypeSmallInteger || fieldType == AGSFieldTypeInteger ||
                              fieldType == AGSFieldTypeSingle       || fieldType == AGSFieldTypeDouble));
}

-(BOOL)isADateField:(AGSField *)field
{
    //get field type:
    AGSFieldType fieldType = field.type;
    return (fieldType == AGSFieldTypeDate);
}


#pragma mark -
#pragma mark Lazy Loads

//dictionary of attribute names to the AGSField that defines the actual
//field
-(NSDictionary *)fieldDictionary
{
    //lazy loaded. Computation should only happen the first time this is called
    if(_fieldDictionary == nil)
    {
        //instantiate new dictionary with count equivalent to number of fields
        NSMutableDictionary *aDict = 
        [NSMutableDictionary dictionaryWithCapacity:self.featureLayer.fields.count];
        
        for (AGSField *aField in self.featureLayer.fields)
        {
            [aDict setObject:aField forKey:aField.name];
        }
        
        
        //finally, set new dictionary to property value
        self.fieldDictionary = aDict;
    }
    
    return _fieldDictionary;
}

//dictionary of actual attribute names to the labels that should be
//presented
-(NSDictionary *)fieldNamesDictionary
{
    if (_fieldNamesDictionary == nil) {
        NSMutableDictionary *aDict = [NSMutableDictionary 
                                      dictionaryWithCapacity:self.popup.popupInfo.fieldInfos.count];
        
        for (AGSPopupFieldInfo *fi in self.popup.popupInfo.fieldInfos)
        {
            [aDict setObject:fi.label forKey:fi.fieldName];
        }
        
        //finally, set new dictionary to propety value
        self.fieldNamesDictionary = aDict;
    }
    
    return _fieldNamesDictionary;
}

//dictionary of AGSFields to the the corresponding FieldInfo in the
//popupInfo
-(NSDictionary *)fieldInfosDictionary
{
    if(_fieldInfosDictionary == nil)
    {
        NSMutableDictionary *aDict = [NSMutableDictionary 
                                      dictionaryWithCapacity:self.popup.popupInfo.fieldInfos.count];
        
        for(AGSPopupFieldInfo *fi in self.popup.popupInfo.fieldInfos)
        {
            AGSField *keyField = [self.fieldDictionary objectForKey:fi.fieldName];
            
            [aDict setObject:fi             //object if FieldInfo
                    forKey:[NSValue valueWithNonretainedObject:keyField]];   //have to do this so copyWithZone isn't called
        }
        
        self.fieldInfosDictionary = aDict;
    }
    
    return _fieldInfosDictionary;
}

-(AGSFieldType)fieldTypeForFieldInfo:(AGSPopupFieldInfo *)fieldInfo
{
    AGSField *field = [self.fieldDictionary valueForKey:fieldInfo.fieldName];
    return field.type;
}

-(AGSDomain *)domainForFieldInfo:(AGSPopupFieldInfo *)fieldInfo
{
    AGSField *field = [self.fieldDictionary valueForKey:fieldInfo.fieldName];
    return field.domain;
}

-(int)lengthForFieldInfo:(AGSPopupFieldInfo *)fieldInfo
{
    AGSField *field = [self.fieldDictionary valueForKey:fieldInfo.fieldName];
    return field.length;
}


@end
