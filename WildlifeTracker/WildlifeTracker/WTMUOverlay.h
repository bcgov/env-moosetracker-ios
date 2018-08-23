#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "WTMUManager.h"

@interface WTMUOverlay : NSObject <MKOverlay>

@property (nonatomic, strong) MKPolygon *polygon;

- (instancetype)initWithMU:(WTManagementUnit *)mu;

- (MKOverlayRenderer *)renderer;

@end
