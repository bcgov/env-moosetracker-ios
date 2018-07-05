//
//  WTMUOverlay.h
//  WildlifeTracker
//
//  Created by John Griffith on 2016-02-16.
//  Copyright © 2016 John Griffith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "WTMUManager.h"

@interface WTMUOverlay : NSObject <MKOverlay>

@property (nonatomic, strong) MKPolygon *polygon;

- (instancetype)initWithMU:(WTManagementUnit *)mu;

- (MKOverlayRenderer *)renderer;

@end
