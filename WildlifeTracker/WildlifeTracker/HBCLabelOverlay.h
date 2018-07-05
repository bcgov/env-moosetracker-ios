//
//  HBCLabelOverlay.h
//  HuntingBC
//
//  Created by John Griffith on 2013-09-21.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface HBCLabelOverlay : NSObject <MKOverlay>

@property (nonatomic, strong) NSString *label;
@property (nonatomic) CGSize sizeWith80PointFont;

- (UIImage *)imageForZoomScale:(MKZoomScale)zoomScale;
- (void)setImage:(UIImage *)image forZoomScale:(MKZoomScale)zoomScale;

@end
