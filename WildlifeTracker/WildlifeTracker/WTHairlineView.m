#import "WTHairlineView.h"

@implementation WTHairlineView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
    UIColor *color = self.lineColor ? self.lineColor : [UIColor grayColor];
    CGRect pathRect;
    CGFloat lineWidth = 1.0 / [[UIScreen mainScreen] scale];
    pathRect.origin = self.bounds.origin;
    if (self.bounds.size.width > self.bounds.size.height) {
        pathRect.size.width = self.bounds.size.width;
        pathRect.size.height = lineWidth;
    } else {
        pathRect.size.width = lineWidth;
        pathRect.size.height = self.bounds.size.height;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectIntersection(rect, pathRect)];
    [color setFill];
    [path fill];
}

@end
