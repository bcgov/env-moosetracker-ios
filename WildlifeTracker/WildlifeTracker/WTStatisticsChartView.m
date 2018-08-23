#import "WTStatisticsChartView.h"

@implementation WTStatisticsChartDataItem
@end

@interface WTStatisticsChartView ()

@property (nonatomic) NSInteger maxHours;
@property (nonatomic) NSInteger maxMoose;
@property (nonatomic) CGFloat barWidth;
@property (nonatomic) CGFloat barSpacing;
@property (nonatomic, strong) NSMutableArray <UILabel *> *barLabels;
@property (nonatomic, strong) UILabel *leftZeroLabel;
@property (nonatomic, strong) UILabel *leftTitleLabel;
@property (nonatomic, strong) UILabel *leftMaxLabel;
@property (nonatomic, strong) UILabel *rightZeroLabel;
@property (nonatomic, strong) UILabel *rightTitleLabel;
@property (nonatomic, strong) UILabel *rightMaxLabel;

@end

#define MARGIN_X 40.0
#define LABEL_X_SPACING 22.0
#define MARGIN_TOP 18.0
#define MARGIN_BOTTOM 8.0
#define MAX_BAR_WIDTH 24.0
#define MIN_BAR_SPACING 10.0
#define LABEL_HEIGHT 24.0

#define SCALE_NUMBER_FONT_SIZE 12.0
#define SCALE_TEXT_FONT_SIZE 10.0

@implementation WTStatisticsChartView

- (void)setDataItems:(NSArray<WTStatisticsChartDataItem *> *)dataItems
{
    _dataItems = dataItems;
    
    self.maxHours = 0;
    self.maxMoose = 0;
    
    for (UILabel *label in self.barLabels) {
        [label removeFromSuperview];
    }
    self.barLabels = [NSMutableArray array];
    
    NSUInteger numItems = dataItems.count;
    if (numItems < 1)
        return;
    
    for (WTStatisticsChartDataItem *item in dataItems) {
        if (item.hours > self.maxHours) {
            self.maxHours = item.hours;
        }
        if (item.moose > self.maxMoose) {
            self.maxMoose = item.moose;
        }
        UILabel *label = [[UILabel alloc] init];
        label.text = item.label;
        label.font = [UIFont systemFontOfSize:SCALE_TEXT_FONT_SIZE];
        label.translatesAutoresizingMaskIntoConstraints = YES; // Will position these manually
        [label sizeToFit];
        [self addSubview:label];
        [self.barLabels addObject:label];
    }
    
    self.leftMaxLabel.text = [NSString stringWithFormat:@"%ld", (long)self.maxHours];
    [self.leftMaxLabel sizeToFit];

    // Adjust maxMoose to be higher than the actual max so the bars look better (shorter)
    if (self.maxMoose > 15) {
        // Add 10% and round up to multiple of 5
        self.maxMoose = (((self.maxMoose * 11) + 50) / 50) * 5;
    } else if (self.maxMoose > 4) {
        // Round up to next even number
        self.maxMoose = ((self.maxMoose + 2) / 2) * 2;
    } else if (self.maxMoose > 0) {
        // Add 1
        self.maxMoose += 1;
    }
    
    self.rightMaxLabel.text = [NSString stringWithFormat:@"%ld", (long)self.maxMoose];
    [self.rightMaxLabel sizeToFit];
    
    [self setNeedsDisplay];
}

- (void)setHoursColor:(UIColor *)hoursColor
{
    _hoursColor = hoursColor;
    self.leftZeroLabel.textColor = hoursColor;
    self.leftTitleLabel.textColor = hoursColor;
    self.leftMaxLabel.textColor = hoursColor;
    [self setNeedsDisplay];
}

- (void)setMooseColor:(UIColor *)mooseColor
{
    _mooseColor = mooseColor;
    self.rightZeroLabel.textColor = mooseColor;
    self.rightTitleLabel.textColor = mooseColor;
    self.rightMaxLabel.textColor = mooseColor;
    [self setNeedsDisplay];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.hoursColor = [UIColor blueColor];
    self.mooseColor = [UIColor redColor];
    
    self.leftZeroLabel = [[UILabel alloc] init];
    self.leftZeroLabel.text = @"0";
    self.leftZeroLabel.font = [UIFont boldSystemFontOfSize:SCALE_NUMBER_FONT_SIZE];
    self.leftZeroLabel.textColor = self.hoursColor;
    self.leftZeroLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [self.leftZeroLabel sizeToFit];
    [self addSubview:self.leftZeroLabel];

    self.leftTitleLabel = [[UILabel alloc] init];
    self.leftTitleLabel.text = @"HOURS";
    self.leftTitleLabel.font = [UIFont boldSystemFontOfSize:SCALE_TEXT_FONT_SIZE];
    self.leftTitleLabel.textColor = self.hoursColor;
    self.leftTitleLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.leftTitleLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [self.leftTitleLabel sizeToFit];
    [self addSubview:self.leftTitleLabel];

    self.leftMaxLabel = [[UILabel alloc] init];
    self.leftMaxLabel.text = @"0";
    self.leftMaxLabel.font = [UIFont boldSystemFontOfSize:SCALE_NUMBER_FONT_SIZE];
    self.leftMaxLabel.textColor = self.hoursColor;
    self.leftMaxLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [self.leftMaxLabel sizeToFit];
    [self addSubview:self.leftMaxLabel];
    
    self.rightZeroLabel = [[UILabel alloc] init];
    self.rightZeroLabel.text = @"0";
    self.rightZeroLabel.font = [UIFont boldSystemFontOfSize:SCALE_NUMBER_FONT_SIZE];
    self.rightZeroLabel.textColor = self.mooseColor;
    self.rightZeroLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [self.rightZeroLabel sizeToFit];
    [self addSubview:self.rightZeroLabel];
    
    self.rightTitleLabel = [[UILabel alloc] init];
    self.rightTitleLabel.text = @"MOOSE";
    self.rightTitleLabel.font = [UIFont boldSystemFontOfSize:SCALE_TEXT_FONT_SIZE];
    self.rightTitleLabel.textColor = self.mooseColor;
    self.rightTitleLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.rightTitleLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [self.rightTitleLabel sizeToFit];
    [self addSubview:self.rightTitleLabel];
    
    self.rightMaxLabel = [[UILabel alloc] init];
    self.rightMaxLabel.text = @"0";
    self.rightMaxLabel.font = [UIFont boldSystemFontOfSize:SCALE_NUMBER_FONT_SIZE];
    self.rightMaxLabel.textColor = self.mooseColor;
    self.rightMaxLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [self.rightMaxLabel sizeToFit];
    [self addSubview:self.rightMaxLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSUInteger numItems = self.dataItems.count;
    if (numItems < 1)
        return;

    CGFloat minTotalSpace = 2.0 * MARGIN_X + (numItems - 1) * MIN_BAR_SPACING;
    self.barWidth = floorf((self.bounds.size.width - minTotalSpace) / numItems);
    if (self.barWidth > MAX_BAR_WIDTH) {
        self.barWidth = MAX_BAR_WIDTH;
    }
    self.barSpacing = (self.bounds.size.width - (2.0 * MARGIN_X + self.barWidth * numItems)) / (numItems - 1);

    for (NSUInteger i = 0; i < self.barLabels.count; i++) {
        CGFloat barCenterX = roundf(MARGIN_X + (i * self.barWidth) + (i * self.barSpacing) + (self.barWidth / 2.0));
        CGRect frame = self.barLabels[i].frame;
        frame.origin.y = self.bounds.origin.y + (self.bounds.size.height - (frame.size.height + MARGIN_BOTTOM));
        frame.origin.x = barCenterX - (frame.size.width / 2.0);
        self.barLabels[i].frame = frame;
    }

    CGFloat maxBarHeight = self.bounds.size.height - (MARGIN_TOP + LABEL_HEIGHT);
    CGFloat leftX = MARGIN_X - LABEL_X_SPACING;
    CGFloat rightX = MARGIN_X + numItems * self.barWidth + (numItems - 1) * self.barSpacing + LABEL_X_SPACING;
    self.leftMaxLabel.center = CGPointMake(leftX, MARGIN_TOP);
    self.leftTitleLabel.center = CGPointMake(leftX, MARGIN_TOP + maxBarHeight / 2.0);
    self.leftZeroLabel.center = CGPointMake(leftX, MARGIN_TOP + maxBarHeight);
    self.rightMaxLabel.center = CGPointMake(rightX, MARGIN_TOP);
    self.rightTitleLabel.center = CGPointMake(rightX, MARGIN_TOP + maxBarHeight / 2.0);
    self.rightZeroLabel.center = CGPointMake(rightX, MARGIN_TOP + maxBarHeight);
}

- (void)drawRect:(CGRect)rect
{
    NSUInteger numItems = self.dataItems.count;
    CGFloat maxBarHeight = self.bounds.size.height - (MARGIN_TOP + LABEL_HEIGHT);
    CGFloat barBottom = self.bounds.origin.y + MARGIN_TOP + maxBarHeight;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGFloat lineWidth = 1.0 / self.contentScaleFactor;
    CGContextSetLineWidth(context, lineWidth);
    CGContextAddRect(context, CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, lineWidth / 2.0 + barBottom - self.bounds.origin.y));
    CGContextClip(context);
    for (NSUInteger i = 0; i < numItems; i++) {
        WTStatisticsChartDataItem *item = self.dataItems[i];
        CGFloat barX = roundf(MARGIN_X + (i * self.barWidth) + (i * self.barSpacing));
        if (item.hours != 0) {
            CGFloat height = roundf(maxBarHeight * ((CGFloat)item.hours / (CGFloat)self.maxHours));
            CGContextSetFillColorWithColor(context, [self.hoursColor CGColor]);
            CGPathRef path = CGPathCreateWithRect(CGRectMake(barX - self.barWidth / 3.0, barBottom - height, self.barWidth, height), NULL);
            CGContextAddPath(context, path);
            CGContextSaveGState(context);
            CGContextSetShadow(context, CGSizeMake(-3.0, 3.0), 3.0);
            CGContextFillPath(context);
            CGContextRestoreGState(context);
            CGContextAddPath(context, path);
            CGContextStrokePath(context);
            CGPathRelease(path);
        }
        if (item.moose != 0) {
            CGFloat height = roundf(maxBarHeight * ((CGFloat)item.moose / (CGFloat)self.maxMoose));
            CGContextSetFillColorWithColor(context, [self.mooseColor CGColor]);
            CGPathRef path = CGPathCreateWithRect(CGRectMake(barX + self.barWidth / 3.0, barBottom - height, self.barWidth, height), NULL);
            CGContextAddPath(context, path);
            CGContextSaveGState(context);
            CGContextSetShadow(context, CGSizeMake(-2.0, 3.0), 3.0);
            CGContextFillPath(context);
            CGContextRestoreGState(context);
            CGContextAddPath(context, path);
            CGContextStrokePath(context);
            CGPathRelease(path);
        }
    }
    CGContextRestoreGState(context);
}

@end
