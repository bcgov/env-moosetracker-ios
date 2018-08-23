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
