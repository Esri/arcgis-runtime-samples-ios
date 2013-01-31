/*
 WISimpleCSVParser.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WISimpleCSVParser.h"

@interface WISimpleCSVParser () 
@property (nonatomic, copy, readwrite) NSURL *fileURL;
@property (nonatomic, assign, readwrite) NSInteger latFieldIndex;
@property (nonatomic, assign, readwrite) NSInteger longFieldIndex;
@property (nonatomic, assign, readwrite) NSInteger nameFieldIndex;
@end

@implementation WISimpleCSVParser

@synthesize fileURL         =_fileURL;
@synthesize latField        =_latField;
@synthesize latFieldIndex   =_latFieldIndex;
@synthesize longField       =_longField;
@synthesize longFieldIndex  =_longFieldIndex;
@synthesize nameField       =_nameField;
@synthesize nameFieldIndex  =_nameFieldIndex;


- (id)initWithFileURL:(NSURL*)fileURL {
    if (self = [super init]) {
        self.nameField = @"name";
        self.latField = @"lat";
        self.longField = @"long";
        self.latFieldIndex = -1;
        self.longFieldIndex = -1;
        self.nameFieldIndex = -1;
        self.fileURL = fileURL;
    }
    return self;
}

- (NSArray*)parse {
    if (!self.fileURL) {
        return nil;
    }
    
    // we know that this will be a fileURL so we can use this method
    NSString* fileContents = [NSString stringWithContentsOfURL:self.fileURL 
                                                      encoding:NSUTF8StringEncoding 
                                                         error:nil];
    
    // first, separate by new line
    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:
                                [NSCharacterSet newlineCharacterSet]];
    
    //
    // an array of arrays
    NSMutableArray *rows = [NSMutableArray array];
    
    int i = 0;
    // then break down even further 
    for (NSString *line in allLinedStrings) {
        
        if (line.length == 0) {
            continue;
        }
        
        // choose whatever input identity you have decided. in this case ,
        NSArray* singleStrs = [line componentsSeparatedByString:@","];
        NSMutableArray *rowObjects = [NSMutableArray array];
        int index = 0;
        
        for (NSString *s in singleStrs) {
            
            //
            // if i == 0 we are parsing our column headers line
            if (i == 0) {
                if ([s isEqualToString:self.latField]) {
                    self.latFieldIndex = index;
                }
                else if ([s isEqualToString:self.longField]) {
                    self.longFieldIndex = index;
                }
                else if ([s isEqualToString:self.nameField]) {
                    self.nameFieldIndex = index;
                }
            }
            [rowObjects addObject:s];
            index++;
        }    
        // skip first line (when i==0) which contains the column names
        if (i) {
           [rows addObject:rowObjects];
        }
        i++;
    }
    
    return rows;
}

@end
