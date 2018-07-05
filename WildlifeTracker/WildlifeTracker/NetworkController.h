//
//  NetworkController.h
//  Wildlife Survey Application
//
//  Created by Daniel Chui on 12-02-08.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


/**
 Handles the network calls to the server
 */

#import <Foundation/Foundation.h>

@interface NetworkController : NSObject

+ (NetworkController *)sharedInstance;

- (void)sendAsynchronousRequestWithDictionary:(NSDictionary *)requestValuesDictionary atURL:(NSString *)urlString completion:
                                (void (^)(NSDictionary *result, NSError *error))completion;

- (BOOL) serverIsReachable;

@end
