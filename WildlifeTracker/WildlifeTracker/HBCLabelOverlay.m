//
//  HBCLabelOverlay.m
//  HuntingBC
//
//  Created by John Griffith on 2013-09-21.
//
//

#import <CoreText/CoreText.h>
#import "HBCLabelOverlay.h"

@interface HBCLabelOverlay ()

@property (nonatomic, strong) NSMutableArray *imageList;
@property (nonatomic, strong) NSMutableArray *scaleList;

@end

@implementation HBCLabelOverlay

@synthesize coordinate = _coordinate;
@synthesize boundingMapRect = _boundingMapRect;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _coordinate = CLLocationCoordinate2DMake(500.0, 500.0); // invalid
        self.imageList = [NSMutableArray array];
        self.scaleList = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:@"UIApplicationDidReceiveMemoryWarningNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setLabel:(NSString *)label
{
    _label = label;
    _boundingMapRect = MKMapRectNull;
    
    if (label && CLLocationCoordinate2DIsValid(_coordinate))
        [self calculateBoundingRect];
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
    _boundingMapRect = MKMapRectNull;
    
    if (self.label && CLLocationCoordinate2DIsValid(newCoordinate))
        [self calculateBoundingRect];
}

#define LABEL_SCALE_FACTOR 800.0

- (void)calculateBoundingRect
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.label];
    
    // Set font and size for whole string
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)@"Helvetica-Bold", 80.0, nil);
    NSRange fullRange = NSMakeRange(0, str.length);
    [str addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)ctFont range:fullRange];
    [str addAttribute:(NSString *)kCTFontSizeAttribute value:[NSNumber numberWithFloat:80.0] range:fullRange];
    CFRelease(ctFont);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) str);
    _sizeWith80PointFont = CGSizeZero;
    if (framesetter)
    {
        CFRange fitCFRange = CFRangeMake(0,0);
        _sizeWith80PointFont = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), &fitCFRange);
        CFRelease(framesetter);
    }
    
    // Translate 80 point size to map coordinates
    NSLog(@"%s label=%@", __PRETTY_FUNCTION__, self.label);
    NSLog(@"Calculated 80 point CoreText size: %@", NSStringFromCGSize(_sizeWith80PointFont));
    double newWidth = _sizeWith80PointFont.width * LABEL_SCALE_FACTOR;
    double newHeight = _sizeWith80PointFont.height * LABEL_SCALE_FACTOR;
    MKMapPoint centerMapPoint = MKMapPointForCoordinate(_coordinate);
    _boundingMapRect = MKMapRectMake(centerMapPoint.x - (newWidth / 2.0), centerMapPoint.y - (newHeight / 2.0), newWidth, newHeight);
}

#define MAX_CACHED_IMAGES 3

- (UIImage *)imageForZoomScale:(MKZoomScale)zoomScale
{
    for (int i = 0; i < self.scaleList.count; i++) {
        if (zoomScale == [[self.scaleList objectAtIndex:i] floatValue]) {
            return [self.imageList objectAtIndex:i];
        }
    }
    return nil;
}

- (void)setImage:(UIImage *)image forZoomScale:(MKZoomScale)zoomScale
{
    for (int i = 0; i < self.scaleList.count; i++) {
        if (zoomScale == [[self.scaleList objectAtIndex:i] floatValue]) {
            [self.scaleList removeObjectAtIndex:i];
            [self.imageList removeObjectAtIndex:i];
            break;
        }
    }
    [self.scaleList insertObject:[NSNumber numberWithFloat:zoomScale] atIndex:0];
    [self.imageList insertObject:image atIndex:0];
    if (self.scaleList.count > MAX_CACHED_IMAGES) {
        [self.scaleList removeObjectsInRange:NSMakeRange(MAX_CACHED_IMAGES, self.scaleList.count - MAX_CACHED_IMAGES)];
    }
    if (self.imageList.count > MAX_CACHED_IMAGES) {
        [self.imageList removeObjectsInRange:NSMakeRange(MAX_CACHED_IMAGES, self.imageList.count - MAX_CACHED_IMAGES)];
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    @synchronized(self) {
        [self.imageList removeAllObjects];
        [self.scaleList removeAllObjects];
    }
}

@end
