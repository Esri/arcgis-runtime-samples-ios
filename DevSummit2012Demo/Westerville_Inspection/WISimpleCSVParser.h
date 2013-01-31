/*
 WISimpleCSVParser.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <Foundation/Foundation.h>

/* 
 A very simple CSV parser that expects a specific format. This is only to be used
 to demonstrate the loading of a CSV from another application, such as the Mail.app 
 
 See the sample.csv file located in the 'Supporting Files' group.
 */
@interface WISimpleCSVParser : NSObject

/* Latitude field name */
@property (nonatomic, copy) NSString                *latField;

/* The header index of the latitude field */
@property (nonatomic, assign, readonly) NSInteger   latFieldIndex;

/* Longitude field name */
@property (nonatomic, copy) NSString                *longField;

/* The header index of the longitude field */
@property (nonatomic, assign, readonly) NSInteger   longFieldIndex;

/* The name field associated with a row item in the CSV */
@property (nonatomic, copy) NSString                *nameField;

/* The header index of the name field */
@property (nonatomic, assign, readonly)             NSInteger nameFieldIndex;

/* The URL to the file on disk. This will be set when your application is selected
 to handle the opening of the file */
@property (nonatomic, copy, readonly)               NSURL *fileURL;

/* Initialize our object with the fileURL passed to us from the OS */
- (id)initWithFileURL:(NSURL*)fileURL;

/* Parse the CSV file and return an array of arrays representing the row data */
- (NSArray*)parse;
@end
