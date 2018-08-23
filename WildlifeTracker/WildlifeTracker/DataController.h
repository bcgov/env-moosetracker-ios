#import <Foundation/Foundation.h>

#define SUBMIT_SUCCESSFUL_NOTIFICATION @"WTSubmitSuccessful"
#define SUBMIT_FAILED_NOTIFICATION @"WTSubmitFailed"

@interface WTSightingData : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *mu;
@property (nonatomic) NSInteger numBulls;
@property (nonatomic) NSInteger numCows;
@property (nonatomic) NSInteger numCalves;
@property (nonatomic) NSInteger numUnidentified;
@property (nonatomic) NSInteger numHours;

/// If set to true, broadcast a notification for success/failure.
@property (nonatomic) BOOL sendNotification;

@end

@interface DataController : NSObject

+ (DataController *)sharedInstance;

- (void)submitData:(WTSightingData *)sightingData;

/// Call this function to resubmit any data that was not able to be submitted on previous attempts.
- (void)resubmitUnsentData;

- (NSArray<WTSightingData *> *)queryFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate region:(NSString *)region mu:(NSString *)mu;

@end
