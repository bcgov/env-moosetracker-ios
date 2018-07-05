//
//  AlarmController.h
//  Wildlife Survey Application
//
//  Created by Daniel Chui on 12-02-08.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlarmController : NSObject

+ (AlarmController *)sharedInstance;

@property (nonatomic) BOOL remindersEnabled;
@property (nonatomic) BOOL soundEnabled;

// Add an alert every day at 8 pm for the next 2 weeks.
- (void)addAlertsForNext2Weeks;

@end
