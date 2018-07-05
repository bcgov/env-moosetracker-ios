//
//  HBCLabelOverlayRenderer.h
//  HuntingBC
//
//  Created by John Griffith on 2013-10-14.
//
//

#import <MapKit/MapKit.h>
#import "HBCLabelOverlay.h"

@interface HBCLabelOverlayRenderer : MKOverlayRenderer

- (instancetype)initWithOverlay:(HBCLabelOverlay *)overlay;

@end
