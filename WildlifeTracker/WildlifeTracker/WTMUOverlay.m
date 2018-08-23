#import "WTMUOverlay.h"
#import "WTMUOverlayRenderer.h"

@interface WTMUOverlay ()

@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) MKMapRect bounds;

@end

@implementation WTMUOverlay

- (instancetype)initWithMU:(WTManagementUnit *)mu
{
    self = [super init];
    if (self) {
        self.polygon = mu.polygon;
        self.center = mu.polygon.coordinate;
        self.bounds = mu.polygon.boundingMapRect;
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.center;
}

- (MKMapRect)boundingMapRect
{
    return self.bounds;
}

- (MKOverlayRenderer *)renderer
{
    WTMUOverlayRenderer *result = nil;
    if (self.polygon) {
        result = [[WTMUOverlayRenderer alloc] initWithOverlay:self];
    }
    return result;
}

@end
