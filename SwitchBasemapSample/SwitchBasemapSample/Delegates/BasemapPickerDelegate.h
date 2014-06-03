//
//  BasemapPickerDelegate.h
//  SwitchBasemapSample
//
//  Created by Gagandeep Singh on 5/6/14.
//  Copyright (c) 2014 Gagandeep Singh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BasemapPickerDelegate <NSObject>

//notifies that the user selected a basemap from either a list or collection
-(void)basemapPickerController:(UIViewController*)controller didSelectBasemap:(AGSWebMapBaseMap*)basemap;

//notifies that the user canceled or closed the list or collection without
//making any selection
-(void)basemapPickerControllerDidCancel:(UIViewController*)controller;

@end
