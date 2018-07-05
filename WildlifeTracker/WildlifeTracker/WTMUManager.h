//
//  WTMUManager.h
//  WildlifeTracker
//
//  Created by John Griffith on 2016-02-24.
//  Copyright © 2016 John Griffith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface WTManagementUnit : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) MKPolygon *polygon;

@end

#define MUS_LOADED_NOTIFICATION @"ManagementUnitsLoaded"

@interface WTMUManager : NSObject

+ (WTMUManager *)sharedInstance;

+ (NSString *)parentRegionForName:(NSString *)muName;

- (NSString *)muFromLocation:(CLLocationCoordinate2D)location;

- (BOOL)managementUnitsLoaded;

/// Returns nil if management units not finished loading - check using -managementUnitsLoaded
- (NSArray<WTManagementUnit *> *)allManagementUnits;

@end
