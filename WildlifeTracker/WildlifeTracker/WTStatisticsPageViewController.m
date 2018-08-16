//
//  WTStatisticsPageViewController.m
//  WildlifeTracker
//
//  Created by John Griffith on 2016-06-29.
//  Copyright © 2016 John Griffith. All rights reserved.
//

#import "WTStatisticsPageViewController.h"
#import "WTStatisticsViewController.h"

@interface WTStatisticsPageViewController () <UIPageViewControllerDataSource>

@end

@implementation WTStatisticsPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = self;
    
    WTStatisticsViewController *initialVC = [self.storyboard instantiateViewControllerWithIdentifier:@"statisticsViewController"];
    
    // Set default statistics view to "this year"
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"America/Vancouver"];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
    initialVC.year = components.year;
    
    [self setViewControllers:@[initialVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    WTStatisticsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"statisticsViewController"];
    WTStatisticsViewController *oldVC = (WTStatisticsViewController *)viewController;
    vc.year = oldVC.year + 1;
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    WTStatisticsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"statisticsViewController"];
    WTStatisticsViewController *oldVC = (WTStatisticsViewController *)viewController;
    vc.year = oldVC.year - 1;
    return vc;
}

@end
