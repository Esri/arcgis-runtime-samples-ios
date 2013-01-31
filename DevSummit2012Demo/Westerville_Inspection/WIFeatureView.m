/*
 WIFeatureView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */


#import <ArcGIS/ArcGIS.h>
#import "WIFeatureView.h"
#import "WIDefaultListTableViewCell.h"
#import "WIAttributeUtility.h"

@interface WIFeatureView ()

@property (nonatomic, strong) AGSPopup              *popup;
@property (nonatomic, strong) WIAttributeUtility   *attributeUtility;

@property (nonatomic, strong) UIButton              *inspectButton;

@end

@implementation WIFeatureView

@synthesize featureDelegate     = _featureDelegate;

@synthesize popup               = _popup;
@synthesize attributeUtility    = _attributeUtility;

@synthesize inspectButton       = _inspectButton;


- (id)initWithFrame:(CGRect)frame withPopup:(AGSPopup *)popup
{
    self = [super initWithFrame:frame listViewTableViewType:AGSListviewTypeStaticTitle datasource:self];
    if(self)
    {
        self.popup = popup;
        
        //Attribute utility will help create string representations of our field data
        self.attributeUtility = [[WIAttributeUtility alloc] initWithPopup:self.popup];
        
        self.backgroundColor = [UIColor whiteColor];

        self.inspectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGFloat margin          = 20.0f;
        CGFloat buttonHeight    = 100.0f;
        CGRect inspectButtonFrame = CGRectMake(margin, frame.size.height - (margin + buttonHeight), buttonHeight, buttonHeight);
        self.inspectButton.frame = inspectButtonFrame;
        [self.inspectButton addTarget:self action:@selector(inspectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                        
        [self setSplashImage:[UIImage imageNamed:@"feature_splash.png"]];
        
        [self addSubview:self.inspectButton];
    }
    
    return self;
}

#pragma mark -
#pragma mark AGSListTableViewDataSource
- (NSUInteger)numberOfRows
{
    return self.popup.popupInfo.fieldInfos.count;
}

- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIDefaultListTableViewCell *cell = [tv defaultRowCell];
    
    AGSPopupFieldInfo *fi = [self.popup.popupInfo.fieldInfos objectAtIndex:index];
    AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
    
    cell.nameLabel.text = [NSString stringWithFormat:@"%@: %@", fi.label, [self.attributeUtility attributeStringForField:field]];
    
    return cell;
}

- (NSString *)titleString
{
    NSString *title = @"Feature";
    if (self.popup.popupInfo.title.length > 0) {
        title = self.popup.popupInfo.title;
    }
    return title;
}

#pragma mark -
#pragma mark Buttons
- (void)inspectButtonPressed:(id)sender
{
    //Delegate that we want this feature inspected
    if ([self.featureDelegate respondsToSelector:@selector(featuresView:wantsToInspectFeature:)]) {
        [self.featureDelegate featuresView:self wantsToInspectFeature:self.popup];
    }
    
}

@end
