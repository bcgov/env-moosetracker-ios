#import "HBCLabelOverlayRenderer.h"
#import "HBCLabelRenderer.h"

@interface HBCLabelOverlayRenderer () <HBCRendererDelegate>

@property (nonatomic, strong) HBCLabelRenderer *renderer;

@end

@implementation HBCLabelOverlayRenderer

- (instancetype)initWithOverlay:(HBCLabelOverlay *)overlay
{
    self = [super initWithOverlay:overlay];
    if (self) {
        self.renderer = [[HBCLabelRenderer alloc] initWithOverlay:overlay];
        if (!self.renderer)
            return nil;
        self.renderer.delegate = self;
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
    [self.renderer drawMapRect:mapRect zoomScale:zoomScale inContext:context];
}

@end
