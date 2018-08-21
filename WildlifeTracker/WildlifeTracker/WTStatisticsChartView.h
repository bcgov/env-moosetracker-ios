#import <UIKit/UIKit.h>

@interface WTStatisticsChartDataItem : NSObject

@property (nonatomic, strong) NSString *label;
@property (nonatomic) NSInteger hours;
@property (nonatomic) NSInteger moose;

@end

@interface WTStatisticsChartView : UIView

@property (nonatomic, strong) NSArray <WTStatisticsChartDataItem *> *dataItems;
@property (nonatomic, strong) UIColor *hoursColor;
@property (nonatomic, strong) UIColor *mooseColor;

@end
