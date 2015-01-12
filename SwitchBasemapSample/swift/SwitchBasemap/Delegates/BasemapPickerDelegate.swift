//
// Copyright 2014 ESRI
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

import Foundation
import UIKit
import ArcGIS

protocol BasemapPickerDelegate: class {
    /** Tells the delegate that the user selected a basemap from either a list or collection
    @param controller   List or grid view controller
    @param basemap      The selected basemap
    **/
    func basemapPickerController(controller:UIViewController, didSelectBasemap basemap:AGSWebMapBaseMap)
    
    /** Tells the delegate that the user canceled or closed the list or collection without making any selection
    @param controller   List or grid view controller
    **/
    func basemapPickerControllerDidCancel(controller:UIViewController)
}