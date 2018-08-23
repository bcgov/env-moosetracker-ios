#import <Foundation/Foundation.h>

@interface AlarmController : NSObject

+ (AlarmController *)sharedInstance;

@property (nonatomic) BOOL remindersEnabled;
@property (nonatomic) BOOL soundEnabled;

// Add an alert every day at 8 pm for the next 2 weeks.
- (void)addAlertsForNext2Weeks;

@end
