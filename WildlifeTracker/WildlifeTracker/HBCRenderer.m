//
//  HBCRenderer.m
//  HuntingBC
//
//  Created by John Griffith on 2013-10-14.
//
//

#import "HBCRenderer.h"

@implementation HBCRenderer

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end
