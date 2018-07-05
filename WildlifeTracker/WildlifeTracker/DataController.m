//
//  DataController.m
//  Wildlife Survey Application
//
//  Created by Daniel Chui on 12-02-27.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FMDB.h"
#import "AppDelegate.h"
#import "NetworkController.h"

#import "DataController.h"
#import "SettingsViewController.h"
#import "WTMUManager.h"

@interface WTSightingData ()

@property (nonatomic) sqlite_int64 rowid;

- (NSDictionary *)valuesDictionary;

@end

@implementation WTSightingData

- (instancetype)initWithResultSet:(FMResultSet *)rs
{
    self = [super init];
    if (self) {
        self.rowid = [rs longLongIntForColumn:@"rowid"];
        self.date = [NSDate dateWithTimeIntervalSince1970:[rs longForColumn:@"date"]];
        self.mu = [rs stringForColumn:@"mu"];
        self.numBulls = [rs intForColumn:@"num_bulls"];
        self.numCows = [rs intForColumn:@"num_cows"];
        self.numCalves = [rs intForColumn:@"num_calves"];
        self.numUnidentified = [rs intForColumn:@"num_unknown"];
        self.numHours = [rs intForColumn:@"hours"];
    }
    return self;
}

- (NSDictionary *)valuesDictionary
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:enUSPOSIXLocale];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *installationId = [defaults stringForKey:INSTALLATION_ID_DEFAULTS_KEY];
    
    return @{@"date": [formatter stringFromDate:self.date],
             @"managementUnit": self.mu,
             @"numBulls": @(self.numBulls),
             @"numCows": @(self.numCows),
             @"numCalves": @(self.numCalves),
             @"numUnknown": @(self.numUnidentified),
             @"numHours": @(self.numHours),
             @"platform": @"iphone",
             @"installation": installationId};
}

@end


@interface DataController ()

@property (strong, nonatomic) NetworkController *networkController;
@property (strong, nonatomic) FMDatabaseQueue *dbQueue;

@end

@implementation DataController

static  NSString * const uploadURLString = @"http://moose.nprg.ca/upload_moose.php";
//static  NSString * const uploadURLString = @"http://huntbuddybc.com/api/upload_moose.php";

+ (DataController *)sharedInstance
{
    static DataController *dataController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataController = [[DataController alloc] init];
    });
    return dataController;
}

- (id)init {
    self = [super init];
    if (self) {
        self.networkController = [NetworkController sharedInstance];
        NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSString *appSupportPath = nil;
        if (urls.count > 0) {
            NSURL *url = urls[0];
            appSupportPath = [url path];
        }
        if (appSupportPath) {
            NSError *error;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create Application Support directory: %@", error);
            }
            NSString *dbPath = [appSupportPath stringByAppendingPathComponent:@"sightings.sqlite"];
            NSLog(@"Sightings DB path %@", dbPath);
            self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            if (!self.dbQueue) {
                NSLog(@"ERROR: Failed to create / open sightings.sqlite at path %@", dbPath);
            }
            [self.dbQueue inDatabase:^(FMDatabase *db) {
                [db executeStatements:@"CREATE TABLE IF NOT EXISTS sightings (date INTEGER, region TEXT, mu TEXT, num_bulls INTEGER, num_cows INTEGER, num_calves INTEGER, num_unknown INTEGER, hours INTEGER, comments TEXT, uploaded INTEGER)"];
                [db executeStatements:@"CREATE INDEX IF NOT EXISTS date_index ON sightings(date)"];
                [db executeStatements:@"CREATE INDEX IF NOT EXISTS region_index ON sightings(region)"];
                [db executeStatements:@"CREATE INDEX IF NOT EXISTS mu_index ON sightings(mu)"];
                [db executeStatements:@"CREATE INDEX IF NOT EXISTS uploaded_index ON sightings(uploaded)"];
            }];
        }
    }
    return self;
}


/**
 * submit data here. If the server is unreachable, store it in unsent submissions and return. Otherwise, submit it
 * CALLED BY THE VIEW CONTROLLER FOR INITIAL SUBMISSION
 */
- (void)submitData:(WTSightingData *)sightingData
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // First things first. If a new sighting, store in database with uploaded flag not set.
    if (sightingData.rowid == 0) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            NSArray *values = @[@([sightingData.date timeIntervalSince1970]),
                                [WTMUManager parentRegionForName:sightingData.mu],
                                sightingData.mu,
                                @(sightingData.numBulls),
                                @(sightingData.numCows),
                                @(sightingData.numCalves),
                                @(sightingData.numUnidentified),
                                @(sightingData.numHours),
                                @(0)];
            if (![db executeUpdate:@"INSERT INTO sightings (date, region, mu, num_bulls, num_cows, num_calves, num_unknown, hours, uploaded) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)" withArgumentsInArray:values]) {
                NSLog(@"DB insert failed: %@", [db lastError]);
            } else {
                sightingData.rowid = db.lastInsertRowId;
            }
        }];
    }

    // If no network, don't bother trying right now.
    if (![self.networkController serverIsReachable]) {
        NSLog(@"Server not reachable");
        if (sightingData.sendNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SUBMIT_FAILED_NOTIFICATION object:self];
        }
        return;
    }
    
    // Try to submit in the background.
    NSDictionary *valuesDictionary = [sightingData valuesDictionary];
    [self.networkController sendAsynchronousRequestWithDictionary:valuesDictionary
                                                            atURL:uploadURLString
                                                       completion:^(NSDictionary *result, NSError *error) {
                                                           BOOL success = NO;
                                                           if (result) {
                                                               int newUploadedStatus = 0; // 0 = not uploaded, 1 = success, 2 = rejected by server
                                                               NSLog(@"Asynchronous request succeeded - response: %@", result);
                                                               success = [result[@"success"] boolValue];
                                                               if (success) {
                                                                   newUploadedStatus = 1;
                                                               } else {
                                                                   // If we got a result dict with success = 0, the data was parsed OK but refused by
                                                                   // the server, so no point retrying. It will just be refused again.
                                                                   newUploadedStatus = 2;
                                                               }
                                                               if (sightingData.rowid > 0) { // Should always be the case unless there was a DB insert error earlier.
                                                                   [self.dbQueue inDatabase:^(FMDatabase *db) {
                                                                       if (![db executeUpdate:@"UPDATE sightings SET uploaded = ? WHERE rowid = ?", @(newUploadedStatus), @(sightingData.rowid)]) {
                                                                           NSLog(@"Failed to update uploaded status: %@", db.lastError);
                                                                       }
                                                                   }];
                                                               }
                                                           } else {
                                                               NSLog(@"Asynchronous request failed: %@", error);
                                                           }
                                                           if (sightingData.sendNotification) {
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   if (success) {
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SUBMIT_SUCCESSFUL_NOTIFICATION object:self];
                                                                   } else {
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SUBMIT_FAILED_NOTIFICATION object:self];
                                                                   }
                                                               });
                                                           }
                                                       }];
}

- (void)resubmitUnsentData
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSMutableArray <WTSightingData *> *unsent = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT rowid, date, mu, num_bulls, num_cows, num_calves, num_unknown, hours FROM sightings WHERE uploaded = 0"];
        if (!rs) {
            NSLog(@"Failed to query for unsent sightings: %@", db.lastError);
        } else {
            while ([rs next]) {
                WTSightingData *sighting = [[WTSightingData alloc] initWithResultSet:rs];
                [unsent addObject:sighting];
            }
            [rs close];
        }
    }];
    for (WTSightingData *sighting in unsent) {
        [self submitData:sighting];
    }
}

- (NSArray<WTSightingData *> *)queryFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate region:(NSString *)region mu:(NSString *)mu
{
    NSMutableArray *args = [NSMutableArray array];
    NSMutableString *whereClause = [NSMutableString stringWithString:@""];
    if (mu) {
        if (whereClause.length > 0) {
            [whereClause appendString:@" AND"];
        }
        [whereClause appendString:@" mu = ?"];
        [args addObject:mu];
    } else if (region) {
        if (whereClause.length > 0) {
            [whereClause appendString:@" AND"];
        }
        [whereClause appendString:@" region = ?"];
        [args addObject:region];
    }
    if (fromDate) {
        if (whereClause.length > 0) {
            [whereClause appendString:@" AND"];
        }
        [whereClause appendString:@" date >= ?"];
        [args addObject:@([fromDate timeIntervalSince1970])];
    }
    if (toDate) {
        if (whereClause.length > 0) {
            [whereClause appendString:@" AND"];
        }
        [whereClause appendString:@" date < ?"];
        [args addObject:@([toDate timeIntervalSince1970])];
    }
    NSMutableArray<WTSightingData *> *result = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs;
        NSMutableString *query = [NSMutableString stringWithString:@"SELECT rowid, date, mu, num_bulls, num_cows, num_calves, num_unknown, hours FROM sightings"];
        if (whereClause.length > 0) {
            [query appendString:@" WHERE"];
            [query appendString:whereClause];
            [query appendString:@" ORDER BY date"];
            NSLog(@"Sightings DB query: %@ args:%@", query, args);
            rs = [db executeQuery:query withArgumentsInArray:args];
        } else {
            [query appendString:@" ORDER BY date"];
            NSLog(@"Sightings DB query: %@", query);
            rs = [db executeQuery:query];
        }
        if (!rs) {
            NSLog(@"Failed to query for sightings: %@", db.lastError);
        } else {
            while ([rs next]) {
                WTSightingData *sighting = [[WTSightingData alloc] initWithResultSet:rs];
                [result addObject:sighting];
            }
            [rs close];
        }
    }];
    return result;
}

@end
