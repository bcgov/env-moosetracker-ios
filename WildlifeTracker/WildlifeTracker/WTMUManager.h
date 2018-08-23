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
