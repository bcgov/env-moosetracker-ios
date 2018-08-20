//
//  HBCLabelRenderer.m
//  HuntingBC
//
//  Created by John Griffith on 2013-10-14.
//
//

#import <CoreText/CoreText.h>
#import "HBCLabelRenderer.h"

@interface HBCLabelRenderer ()
@property (nonatomic, weak) HBCLabelOverlay *overlay;
@end

@implementation HBCLabelRenderer

- (instancetype)initWithOverlay:(HBCLabelOverlay *)overlay
{
    self = [super init];
    if (self) {
        self.overlay = overlay;
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
    MKMapRect theMapRect = self.overlay.boundingMapRect;
    CGRect theRect = [self.delegate rectForMapRect:theMapRect];
    
    UIImage *image;
    @synchronized (self.overlay) {
        image = [self.overlay imageForZoomScale:zoomScale];
        if (!image) {
            image = [self drawImageForZoomScale:zoomScale size:theRect.size];
            if (image)
                [self.overlay setImage:image forZoomScale:zoomScale];
        }
    }
    
    if (image) {
        UIGraphicsPushContext(context);
        [image drawInRect:theRect];
        UIGraphicsPopContext();
    }
}

- (UIImage *)drawImageForZoomScale:(MKZoomScale)zoomScale size:(CGSize)size
{
    // Only draw labels within a range of zoom scales
    if ((zoomScale < 0.0001) || (zoomScale > 0.002))
        return nil;
    
    UIImage *result = nil;
    HBCLabelOverlay *overlay = (HBCLabelOverlay *)self.overlay;
    
    CGRect imageBounds = CGRectMake(0, 0, ceilf(size.width * zoomScale), ceilf(size.height * zoomScale));
    NSLog(@"Drawing label image for %@ zoomScale=%f size=%@", [overlay.label stringByReplacingOccurrencesOfString:@"\n" withString:@" "], zoomScale, NSStringFromCGSize(imageBounds.size));
    
    // Shortcut - use previously calculated width to compute desired font size
    CGFloat fontSize = 80.0 * imageBounds.size.width / overlay.sizeWith80PointFont.width;
    
    CTTextAlignment alignment = kCTTextAlignmentCenter;
    
    CTParagraphStyleSetting alignmentSetting;
    alignmentSetting.spec = kCTParagraphStyleSpecifierAlignment;
    alignmentSetting.valueSize = sizeof(CTTextAlignment);
    alignmentSetting.value = &alignment;
    
    CTParagraphStyleSetting settings[1] = {alignmentSetting};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 1);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                (__bridge id)(paragraphStyle), (__bridge id)kCTParagraphStyleAttributeName,
                                nil];
    CFRelease(paragraphStyle);
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:overlay.label attributes:attributes];
    
    // Set font and size for whole string
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)@"Helvetica-Bold", fontSize, nil);
    NSRange fullRange = NSMakeRange(0, str.length);
    [str addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)ctFont range:fullRange];
    [str addAttribute:(NSString *)kCTFontSizeAttribute value:[NSNumber numberWithFloat:fontSize] range:fullRange];
    [str addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)[[UIColor greenColor] CGColor] range:fullRange];
    CFRelease(ctFont);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) str);
    if (framesetter)
    {
        UIGraphicsBeginImageContextWithOptions(imageBounds.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGRect pathRect = imageBounds;
        pathRect.size.height *= 2.0; // Ensure last line is not omitted if our size is slightly too small
        
        // Text ends up drawn inverted, so we have to reverse it.
        CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
        CGContextTranslateCTM(ctx, 0, pathRect.size.height);
        CGContextScaleCTM(ctx, 1, -1 );
        
        // Set the rectangle for drawing in.
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, pathRect);
        
        // Create the frame and draw it into the graphics context
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        if (frame) {
            CGContextSetAlpha(ctx, 0.5f);
            CTFrameDraw(frame, ctx);
            CFRelease(frame);
        }
        CFRelease(framesetter);
        CFRelease(path);
        
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return result;
}

@end
