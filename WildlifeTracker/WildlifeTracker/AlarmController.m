//
//  AlarmController.m
//  Wildlife Survey Application
//
//  Created by Daniel Chui on 12-02-08.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlarmController.h"

#define REMINDERS_ENABLED_PREFS_KEY @"reminders_enabled"
#define SOUND_ENABLED_PREFS_KEY @"sound_enabled"

#define NOTIFICATION_SOUND_NAME @"moose.caf"

@implementation AlarmController

+ (AlarmController *)sharedInstance
{
    static AlarmController *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[AlarmController alloc] init];
    });
    return singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        
        //Location services disabled right now
        
        //[self prepareLocationManager];

        //this will alert you everyday at sundown during hunting season
        //do it on first startup of app?
        
//        NSDate *currentDate = [NSDate date];
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"YYYY-MM-d"];
//        NSString *dateString;
//        dateString = [[dateFormatter stringFromDate:currentDate] stringByAppendingString:@" 20:00:00"];
////        NSLog (@"Date: %@", dateString);
//        NSDateFormatter *newDateFormatter = [[NSDateFormatter alloc] init];
//        [newDateFormatter setDateFormat:@"YYYY-MM-d HH:mm:ss"];
//        NSDate *newDate = [newDateFormatter dateFromString:dateString];
//        NSLog (@"New date: %@", newDate);
//         
//        NSLog(@"Alarm controller was initialized");
        
        // Check for special case "first time" startup in which the reminders enabled prefs should be set to YES.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![[[defaults dictionaryRepresentation] allKeys] containsObject:REMINDERS_ENABLED_PREFS_KEY]) {
            // Key not present - first time startup.
            [defaults setBool:YES forKey:REMINDERS_ENABLED_PREFS_KEY];
            [defaults setBool:YES forKey:SOUND_ENABLED_PREFS_KEY];
            [defaults synchronize];
        }
    }  
    return self;
    
}

- (BOOL)remindersEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:REMINDERS_ENABLED_PREFS_KEY];
}

- (void)setRemindersEnabled:(BOOL)remindersEnabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL oldSetting = [defaults boolForKey:REMINDERS_ENABLED_PREFS_KEY];
    if (oldSetting != remindersEnabled) {
        [defaults setBool:remindersEnabled forKey:REMINDERS_ENABLED_PREFS_KEY];
        [defaults synchronize];
        
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        if (remindersEnabled) {
            [self addAlertsForNext2Weeks];
        }
    }
}

- (BOOL)soundEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:SOUND_ENABLED_PREFS_KEY];
}

- (void)setSoundEnabled:(BOOL)soundEnabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL oldSetting = [defaults boolForKey:SOUND_ENABLED_PREFS_KEY];
    if (oldSetting != soundEnabled) {
        [defaults setBool:soundEnabled forKey:SOUND_ENABLED_PREFS_KEY];
        [defaults synchronize];
        
        if (self.remindersEnabled) {
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            [self addAlertsForNext2Weeks];
        }
    }
}

- (void)addAlertsForNext2Weeks
{
    NSLog(@"Adding alerts for next 2 weeks");
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
    components.hour = 20;
//    components.hour = 13;
//    components.minute = 53;
    NSDate *startDate = [calendar dateFromComponents:components];
    int startTomorrow = 0;
    if ([startDate compare:currentDate] == NSOrderedAscending)
        startTomorrow = 1;
    NSDateComponents *addComponents = [[NSDateComponents alloc] init];
    for (int i = 0; i < 14; i++) {
        addComponents.day = i + startTomorrow;
        NSDate *fireDate = [calendar dateByAddingComponents:addComponents toDate:startDate options:0];
        [self addAlert:fireDate WithMessage:@"Report your moose sightings for today"];
    }
}

- (BOOL)addAlert:(NSDate *)alertDate WithMessage:(NSString *) msgString {
    
    UILocalNotification *newNotification = [[UILocalNotification alloc] init];
    [newNotification setFireDate:alertDate];
    [newNotification setAlertBody:msgString];
    if (self.soundEnabled) {
        newNotification.soundName = NOTIFICATION_SOUND_NAME;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:newNotification];
    //NSLog(@"Added alert");
    
    return true;
}


/**
 **************** LOCATION CODE HERE.************************
 *
 * not used because it drains battery too much
 *
 */

//
//- (void)prepareLocationManager {
//    NSLog(@"Initializing location manager");
//    if ([CLLocationManager locationServicesEnabled]) {
//        NSLog(@"Can monitor location");
//    }
//    else {
//        NSLog(@"CANNOT monitor region");
//    }
//    if ([CLLocationManager regionMonitoringAvailable]) {
//        NSLog(@"REgion monitoring is available");
//    }
//    else {
//        NSLog(@"Region monitoring is not available");
//    }
//    CLLocationManager *manager = [[CLLocationManager alloc] init];
//    manager.delegate = self;
//    CLLocationCoordinate2D edmontonCoordinate;
//    //coordinates of edmonton according to wikipedia
//    edmontonCoordinate.latitude = 53.54;
//    edmontonCoordinate.longitude = -113.49;
//    //radisu was calculated by using area of Edmonton according to wikipedia, and assuming it is a circle
//    CLRegion *edmontonRegion = [[CLRegion alloc] initCircularRegionWithCenter:edmontonCoordinate radius:15000 identifier:@"Edmonton"];
//    
//    
//    CLLocationCoordinate2D lorneCoordinate;
//    lorneCoordinate.latitude = 53.277404;
//    lorneCoordinate.longitude = -112.797232;
//    CLRegion *lorneRegion = [[CLRegion alloc] initCircularRegionWithCenter:lorneCoordinate radius:10000 identifier:@"Lorne's house"];
//    
//    //[manager startMonitoringForRegion:region desiredAccuracy:kCLLocationAccuracyThreeKilometers];
//    [manager startUpdatingLocation];
//    [manager startMonitoringSignificantLocationChanges];
//    NSLog(@"Significant monitoring available: %d", [CLLocationManager significantLocationChangeMonitoringAvailable]);
//    NSLog(@"Manager delegate: %@", [manager delegate]);
//    if (1) {
//        NSLog(@"COOKIES");
//    }
//    self.locationManager = manager;
//    
//    /*
//    CLLocationManager *manager2 = [[CLLocationManager alloc] init];
//    manager2.delegate = self;
//    manager2.purpose = @"Using update location";
//    [manager2 startUpdatingLocation];
//    NSLog(@"Ended alarm controller init");
//    */
//}
//
//
//
//
//-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
//    NSLog(@"In EDMONTON");
//    NSLog(@"didEnterRegion called");
//    [self addAlert: [NSDate dateWithTimeIntervalSinceNow:60] WithMessage:@"Used region to get this; am in Edmonton"];
//}
//
//-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
//    NSLog(@"Exited Edmonton");
//    [self addAlert: [NSDate dateWithTimeIntervalSinceNow:60] WithMessage:@"Left Edmonton"];
//}
//
//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
//    NSLog(@"Location changed");
//    NSLog(@"Location: %@", [newLocation description]);
//    
//    if (alertCount % 10 != 0) {
//        alertCount ++;
//        return;
//        //[self addAlert:[NSDate dateWithTimeIntervalSinceNow:60] WithMessage:[newLocation description]];
//    }
//    else {
//        //[self addAlert:[NSDate dateWithTimeIntervalSinceNow:60] WithMessage:@"Was ODD"];
//    }
//    alertCount++;
//    if (alertedThisHour) {
//        return;
//    }
//    /*
//    UILocalNotification *newNotification = [[UILocalNotification alloc] init];
//    [newNotification setFireDate:nil];
//    [[UIApplication sharedApplication] scheduleLocalNotification:newNotification];
//    */
//    CLLocationCoordinate2D danielCoordinate;
//    danielCoordinate.latitude = 53.617879;
//    danielCoordinate.longitude = -113.448890;
//    CLRegion *danielRegion = [[CLRegion alloc] initCircularRegionWithCenter:danielCoordinate radius:1000 identifier:@"Daniel's house"];
//    if ([danielRegion containsCoordinate:[newLocation coordinate]]) {
//        NSLog(@"At Daniel's house");
//        //UIAlertView *lala = [[UIAlertView alloc] initWithTitle:@"O no" message:@"At daniels house" delegate:self cancelButtonTitle:@"asdg" otherButtonTitles:nil];
//        //[lala show];
//        //lala = nil;
//        [self addAlert:nil WithMessage:@"At Daniel's house"];
//        
//    }
//    
//    CLLocationCoordinate2D bioSciCoordinate;
//    bioSciCoordinate.latitude = 53.529212;
//    bioSciCoordinate.longitude = -113.525280;
//    CLRegion *bioSciRegion = [[CLRegion alloc] initCircularRegionWithCenter:bioSciCoordinate radius:1000 identifier:@"BioSci building"];
//    if ([bioSciRegion containsCoordinate:[newLocation coordinate]]) {
//        //UIAlertView *lala = [[UIAlertView alloc] initWithTitle:@"asdg" message:@"at biosci" delegate:self cancelButtonTitle:@"asdg" otherButtonTitles:nil];
//        //[lala show];
//        //lala = nil;
//        NSLog(@"About to sleep");
//        [self addAlert:nil WithMessage:@"At biosci building"];
//        //[NSThread sleepForTimeInterval:3600];
//        NSLog(@"At %@", [bioSciRegion identifier]);
//    }
//    
//    CLLocationCoordinate2D lorneCoordinate;
//    lorneCoordinate.latitude = 53.277404;
//    lorneCoordinate.longitude = -112.797232;
//    CLRegion *lorneRegion = [[CLRegion alloc] initCircularRegionWithCenter:lorneCoordinate radius:10000 identifier:@"Lorne's house"];
//    
//    if ([lorneRegion containsCoordinate:[newLocation coordinate]]) {
//        //UIAlertView *lala = [[UIAlertView alloc] initWithTitle:@"adsg" message:@"At Lorne's house" delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
//        //[lala show];
//        //lala = nil;
//        [self addAlert:nil WithMessage:@"At Lorne's house"];
//        NSLog(@"At %@", [lorneRegion identifier]);
//    }
//    
//    alertedThisHour = YES;
//
//    
//}
//
//- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
//    NSLog(@"Started monitoring region: %@", [region identifier]);
//    
//}


@end
