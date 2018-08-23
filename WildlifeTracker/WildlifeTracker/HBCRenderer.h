#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol HBCRendererDelegate <NSObject>

- (CGPoint)pointForMapPoint:(MKMapPoint)mapPoint;
- (CGRect)rectForMapRect:(MKMapRect)mapRect;
- (void)setNeedsDisplay;

@end

@interface HBCRenderer : NSObject

@property (nonatomic, weak) id<HBCRendererDelegate> delegate;

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context;

@end
