#import "WTMUManager.h"
#import "FMDB.h"
#import "wkb-ios-Bridging-Header.h"

@implementation WTManagementUnit
@end

@interface WTMUManager ()

@property (nonatomic, strong) NSArray <WTManagementUnit *> *managementUnits;

@end

@implementation WTMUManager

static NSLocale *en_us_locale = nil;

+ (WTMUManager *)sharedInstance
{
    static WTMUManager *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[WTMUManager alloc] init];
    });
    return singleton;
}

+ (NSString *)parentRegionForName:(NSString *)muName
{
    NSString *result = nil;
    NSArray *arr = [muName componentsSeparatedByString:@"-"];
    if (arr.count == 2) {
        // Should always be the case
        result = [arr objectAtIndex:0];
        if ([result isEqualToString:@"7"]) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.locale = [WTMUManager englishLocale];
            int subMU = [formatter numberFromString:[arr objectAtIndex:1]].intValue;
            if ((subMU <= 18) || ((subMU >= 23) && (subMU <= 30)) || ((subMU >= 37) && (subMU <= 41)))
                result = @"7A";
            else
                result = @"7B";
        }
    } else {
        NSLog(@"Error: Cannot determine parent region for MU name %@", muName);
    }
    return result;
}

+ (NSLocale *)englishLocale
{
    if (en_us_locale == nil) {
        if ([[NSLocale availableLocaleIdentifiers] containsObject:@"en_US"]) {
            en_us_locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        } else {
            // ??? What to do here ???
            en_us_locale = [NSLocale currentLocale];
            NSLog(@"ERROR: en_US not found in list of locales!! Using %@", en_us_locale.localeIdentifier);
        }
    }
    return en_us_locale;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadMUs];
        });
    }
    return self;
}

- (NSArray<WTManagementUnit *> *)allManagementUnits
{
    return self.managementUnits;
}

- (BOOL)managementUnitsLoaded
{
    return (self.managementUnits != nil);
}

- (void)loadMUs
{
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"management_units" ofType:@"sqlite"];
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    if (!dbQueue) {
        NSLog(@"Failed to open MU database with path: %@", dbPath);
    }
    [dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT wmu_id, GEOMETRY FROM input"];
        if (!rs) {
            NSLog(@"Failed to query MUs: %@", [db lastError]);
        } else {
            NSMutableArray <WTManagementUnit *> *muList = [NSMutableArray array];
            while (rs.next) {
                NSString *muName = [rs stringForColumnIndex:0];
                NSData *geometry = [rs dataForColumnIndex:1];
                MKPolygon *polygon = [self parsePolygonFromData:geometry];
                WTManagementUnit *mu = [[WTManagementUnit alloc] init];
                mu.name = muName;
                mu.polygon = polygon;
                [muList addObject:mu];
            }
            [rs close];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.managementUnits = muList;
                [[NSNotificationCenter defaultCenter] postNotificationName:MUS_LOADED_NOTIFICATION object:self];
            });
        }
    }];
}

- (MKPolygon *)parsePolygonFromData:(NSData *)data
{
    WKBByteReader *reader = [[WKBByteReader alloc] initWithData:data];
    reader.byteOrder = CFByteOrderLittleEndian;
    int endianness = [[reader readByte] intValue];
    if (endianness != 1) {
        NSLog(@"ERROR: Unknown endianness: %d", endianness);
    }
    NSUInteger wkbType = [[reader readInt] unsignedIntegerValue] & 0x7fffffff;
    if (wkbType % 1000 != 3) {
        NSLog(@"ERROR: incorrect geometry type: %lu", (unsigned long)wkbType);
    }
    WKBPolygon *wkbPoly = [WKBGeometryReader readPolygonWithReader:reader andHasZ:YES andHasM:NO];
    WKBCurve *firstRing = nil;
    if (wkbPoly.numRings > 0) {
        firstRing = wkbPoly.rings[0];
    } else {
        NSLog(@"ERROR: polygon has no rings!");
    }
    if ([firstRing geometryType] != WKB_LINESTRING) {
        NSLog(@"ERROR: first ring geometry type unexpected: %@", [WKBGeometryTypes name:[firstRing geometryType]]);
        firstRing = nil;
    }
    WKBLineString *lineString = (WKBLineString *)firstRing;
    NSUInteger pointCount = lineString.points.count;
    MKPolygon *polygon = nil;
    if (pointCount > 0) {
        CLLocationCoordinate2D *points = malloc(pointCount * sizeof(CLLocationCoordinate2D));
        NSAssert(points != NULL, @"Failed to allocate buffer for shape points");
        for (NSUInteger i = 0; i < pointCount; i++) {
            WKBPoint *wkbPoint = lineString.points[i];
            points[i] = CLLocationCoordinate2DMake([wkbPoint.y doubleValue], [wkbPoint.x doubleValue]);
        }
        polygon = [MKPolygon polygonWithCoordinates:points count:pointCount];
        free(points);
    }
    return polygon;
}

- (NSString *)muFromLocation:(CLLocationCoordinate2D)location
{
    MKMapPoint locPoint = MKMapPointForCoordinate(location);
    for (WTManagementUnit *mu in self.managementUnits) {
        if ([self isPoint:locPoint inPolygon:mu.polygon]) {
            return mu.name;
        }
    }
    return nil;
}

- (BOOL)isPoint:(MKMapPoint)testPoint inPolygon:(MKPolygon *)polygon
{
    // First, check bounding box
    if (!MKMapRectContainsPoint(polygon.boundingMapRect, testPoint))
        return false;
    
    NSUInteger i, j;
    BOOL result = false;
    NSUInteger nvert = polygon.pointCount;
    MKMapPoint *points = polygon.points;
    for (i = 0, j = nvert-1; i < nvert; j = i++) {
        if ( ((points[i].y>testPoint.y) != (points[j].y>testPoint.y)) &&
            (testPoint.x < (points[j].x-points[i].x) * (testPoint.y-points[i].y) / (points[j].y-points[i].y) + points[i].x) )
            result = !result;
    }
    return result;
}

@end
